#!/usr/bin/env python3
"""
Email Verification Tool â€” Multi-Layer Validation with Live Logging
Layers: Syntax â†’ DNS/MX â†’ SMTP Handshake â†’ Catch-All Detection â†’ Risk Scoring
"""

import csv
import re
import smtplib
import socket
import dns.resolver
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from typing import Optional
import json
from datetime import datetime
import sys
import threading

# ============================================================
# CONFIGURATION
# ============================================================

FROM_EMAIL = "verify@yourdomain.com"
DNS_TIMEOUT = 5
SMTP_TIMEOUT = 10
MAX_WORKERS = 5  # Lowered to avoid rate-limiting when SMTP works

# ANSI color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

# Thread-safe print lock
print_lock = threading.Lock()

# Disposable email domains
DISPOSABLE_DOMAINS = {
    "mailinator.com", "guerrillamail.com", "10minutemail.com",
    "tempmail.com", "temp-mail.org", "throwaway.email",
    "yopmail.com", "sharklasers.com", "trashmail.com",
    "maildrop.cc", "getnada.com", "dispostable.com",
    "fakeinbox.com", "emailondeck.com", "spamgourmet.com",
    "burnermail.io", "mintemail.com", "grr.la", "spam4.me",
}


@dataclass
class VerificationResult:
    """Structured result for each email verification."""
    index: int
    name: str
    organization: str
    email: str
    syntax_valid: bool = False
    domain_exists: bool = False
    mx_found: bool = False
    mx_records: list = field(default_factory=list)
    smtp_response: str = ""
    mailbox_valid: Optional[bool] = None
    catch_all_domain: bool = False
    disposable: bool = False
    free_provider: bool = False
    role_based: bool = False
    risk_level: str = "UNKNOWN"
    risk_score: int = 10
    error_message: str = ""
    verified_at: str = ""
    # Per-layer timing
    dns_time_ms: float = 0
    smtp_time_ms: float = 0


class EmailVerifier:
    """Multi-layer email verification engine with live logging."""

    ROLE_PATTERNS = [
        r'^info@', r'^admin@', r'^support@', r'^sales@', r'^contact@',
        r'^hello@', r'^help@', r'^marketing@', r'^billing@', r'^office@',
        r'^team@', r'^hr@', r'^jobs@', r'^careers@', r'^press@',
        r'^media@', r'^webmaster@', r'^postmaster@', r'^abuse@',
        r'^noreply@', r'^no-reply@', r'^donotreply@',
        r'^ceo@', r'^cfo@', r'^cto@', r'^cmo@', r'^coo@',
        r'^director@', r'^head@', r'^principal@', r'^secretary@',
        r'^events@', r'^enquiries@', r'^enquiry@', r'^accounts@',
        r'^alliances@', r'^cmd@', r'^design@',
    ]

    FREE_DOMAINS = {
        'gmail.com', 'yahoo.com', 'yahoo.co.in', 'hotmail.com',
        'outlook.com', 'live.com', 'rediffmail.com', 'aol.com',
        'protonmail.com', 'mail.com', 'gmx.com', 'yandex.com',
        'icloud.com', 'me.com',
    }

    KNOWN_CATCH_ALL = {
        'amazon.com', 'google.com', 'microsoft.com',
    }

    def __init__(self):
        self.stats = {
            'total': 0, 'completed': 0,
            'syntax_fail': 0, 'dns_fail': 0,
            'smtp_valid': 0, 'smtp_invalid': 0, 'smtp_unreachable': 0,
            'low': 0, 'medium': 0, 'high': 0,
        }
        self.stats_lock = threading.Lock()

    def _log(self, index: int, email: str, layer: str, status: str, detail: str = "", color: str = ""):
        """Thread-safe logging."""
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        with print_lock:
            icon = {
                'OK': 'âœ…', 'WARN': 'âš ï¸', 'FAIL': 'âŒ', 'INFO': 'â„¹ï¸',
                'SKIP': 'â­ï¸', 'DONE': 'ðŸ', 'START': 'ðŸ”',
            }.get(status, 'â€¢')
            
            status_color = {
                'OK': Colors.GREEN, 'WARN': Colors.YELLOW, 'FAIL': Colors.RED,
                'INFO': Colors.CYAN, 'SKIP': Colors.GRAY, 'DONE': Colors.MAGENTA,
                'START': Colors.BLUE,
            }.get(status, Colors.RESET)
            
            # Truncate email for display
            email_display = email if len(email) <= 45 else email[:42] + "..."
            
            line = f"{Colors.GRAY}[{timestamp}]{Colors.RESET} {status_color}{icon} [{layer}]{Colors.RESET} #{index:<4} {email_display:<47}"
            if detail:
                line += f" {Colors.GRAY}â†’{Colors.RESET} {detail}"
            if color:
                line = f"{color}{line}{Colors.RESET}"
            
            print(line)
            sys.stdout.flush()

    def validate_syntax(self, email: str) -> bool:
        """RFC 5322 compliant syntax check."""
        if not email or '@' not in email:
            return False
        pattern = r'^[a-zA-Z0-9][a-zA-Z0-9._%+\-]{0,63}@[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$'
        if not re.match(pattern, email):
            return False
        local_part, domain = email.split('@', 1)
        if '..' in local_part or '..' in domain:
            return False
        if '.' not in domain:
            return False
        for label in domain.split('.'):
            if label.startswith('-') or label.endswith('-'):
                return False
        if len(email) > 254 or len(local_part) > 64:
            return False
        return True

    def check_domain_and_mx(self, domain: str) -> tuple:
        """Check domain exists and retrieve MX records."""
        try:
            try:
                dns.resolver.resolve(domain, 'A', lifetime=DNS_TIMEOUT)
                domain_exists = True
            except (dns.resolver.NXDOMAIN, dns.resolver.NoAnswer, dns.resolver.NoNameservers):
                domain_exists = False
            except Exception:
                domain_exists = True

            try:
                answers = dns.resolver.resolve(domain, 'MX', lifetime=DNS_TIMEOUT)
                mx_records = sorted(
                    [(r.preference, str(r.exchange).rstrip('.')) for r in answers],
                    key=lambda x: x[0]
                )
                return domain_exists, mx_records
            except dns.resolver.NoAnswer:
                try:
                    dns.resolver.resolve(domain, 'A', lifetime=DNS_TIMEOUT)
                    return domain_exists, [(0, domain)]
                except Exception:
                    return domain_exists, []
            except dns.resolver.NXDOMAIN:
                return False, []
            except Exception:
                return domain_exists, []
        except Exception:
            return False, []

    def verify_mailbox_smtp(self, email: str, mx_records: list) -> dict:
        """SMTP handshake verification."""
        local_part, domain = email.split('@', 1)
        result = {'valid': None, 'catch_all': False, 'response': '', 'error': ''}

        if not mx_records:
            result['error'] = 'No MX records'
            return result

        for _, mx_host in mx_records:
            try:
                smtp = smtplib.SMTP(timeout=SMTP_TIMEOUT)
                smtp.connect(mx_host)
                smtp.helo(FROM_EMAIL.split('@')[1])
                try:
                    smtp.ehlo(FROM_EMAIL.split('@')[1])
                except Exception:
                    pass
                smtp.mail(FROM_EMAIL)
                code, response = smtp.rcpt(email)
                smtp.quit()

                response_str = response.decode('utf-8', errors='ignore') if isinstance(response, bytes) else str(response)
                result['response'] = f"SMTP {code}: {response_str[:80]}"

                if code == 250:
                    result['valid'] = True
                    return result
                elif code in (550, 551, 552, 553):
                    result['valid'] = False
                    return result
                elif code in (450, 451, 452):
                    result['valid'] = True
                    result['response'] = f"SMTP {code} (temporary): {response_str[:80]}"
                    return result
                else:
                    result['valid'] = None
                    return result
            except smtplib.SMTPServerDisconnected:
                continue
            except smtplib.SMTPConnectError:
                continue
            except socket.timeout:
                continue
            except ConnectionRefusedError:
                continue
            except OSError:
                continue
            except Exception as e:
                result['error'] = str(e)[:100]
                continue

        result['error'] = 'All MX servers unreachable'
        return result

    def check_role_based(self, email: str) -> bool:
        email_lower = email.lower()
        for pattern in self.ROLE_PATTERNS:
            if re.match(pattern, email_lower):
                return True
        return False

    def check_free_provider(self, domain: str) -> bool:
        return domain.lower() in self.FREE_DOMAINS

    def check_disposable(self, domain: str) -> bool:
        return domain.lower() in DISPOSABLE_DOMAINS

    def check_catch_all_domain(self, domain: str) -> bool:
        return domain.lower() in self.KNOWN_CATCH_ALL

    def calculate_risk(self, result: VerificationResult) -> tuple:
        """Calculate risk score (1-10) and level."""
        score = 0
        if not result.syntax_valid:
            return 10, "HIGH"
        if not result.domain_exists or not result.mx_found:
            score += 8
        else:
            score += 1
        if result.mailbox_valid is False:
            score += 9
        elif result.mailbox_valid is None:
            score += 4
        elif result.mailbox_valid is True:
            score += 0
        if result.catch_all_domain:
            score += 3
        if result.disposable:
            score += 7
        if result.free_provider:
            score += 2
        if result.role_based:
            score += 3
        score = min(score, 10)
        if score <= 3:
            level = "LOW"
        elif score <= 6:
            level = "MEDIUM"
        else:
            level = "HIGH"
        return score, level

    def verify_email(self, index: int, name: str, org: str, email: str) -> VerificationResult:
        """Run full verification pipeline with live logging."""
        self._log(index, email, "START", "START", f"Verifying... | {name}")
        
        result = VerificationResult(
            index=index, name=name, organization=org, email=email,
            verified_at=datetime.now().isoformat()
        )

        # ----- LAYER 1: SYNTAX -----
        t_start = datetime.now()
        result.syntax_valid = self.validate_syntax(email)
        if not result.syntax_valid:
            result.error_message = "Syntax invalid"
            result.risk_score, result.risk_level = self.calculate_risk(result)
            with self.stats_lock: self.stats['syntax_fail'] += 1
            self._log(index, email, "SYNTAX", "FAIL", "Invalid email format", Colors.RED)
            return result
        self._log(index, email, "SYNTAX", "OK", "Format valid")

        # ----- LAYER 2: DNS / MX -----
        domain = email.split('@')[1]
        dns_start = datetime.now()
        result.domain_exists, result.mx_records = self.check_domain_and_mx(domain)
        result.mx_found = len(result.mx_records) > 0
        result.dns_time_ms = (datetime.now() - dns_start).total_seconds() * 1000

        if not result.mx_found:
            result.error_message = "No MX records found"
            with self.stats_lock: self.stats['dns_fail'] += 1
            self._log(index, email, "DNS/MX", "FAIL", "No mail server found for domain", Colors.RED)
            result.risk_score, result.risk_level = self.calculate_risk(result)
            return result
        
        mx_list = ", ".join([f"{host}" for _, host in result.mx_records[:3]])
        a_status = "domainâœ…" if result.domain_exists else "domainâš ï¸"
        self._log(index, email, "DNS/MX", "OK", f"MX: {mx_list} ({a_status}) | {result.dns_time_ms:.0f}ms")

        # ----- HEURISTIC CHECKS -----
        result.role_based = self.check_role_based(email)
        result.free_provider = self.check_free_provider(domain)
        result.disposable = self.check_disposable(domain)
        result.catch_all_domain = self.check_catch_all_domain(domain)

        flags = []
        if result.role_based: flags.append("ROLE-BASED")
        if result.free_provider: flags.append("FREE-PROVIDER")
        if result.catch_all_domain: flags.append("CATCH-ALL")
        if result.disposable: flags.append("DISPOSABLE")
        if flags:
            self._log(index, email, "HEURISTIC", "WARN", f"Flags: {', '.join(flags)}", Colors.YELLOW)
        else:
            self._log(index, email, "HEURISTIC", "OK", "Clean â€” no risk flags")

        # ----- LAYER 3: SMTP HANDSHAKE -----
        smtp_start = datetime.now()
        smtp_result = self.verify_mailbox_smtp(email, result.mx_records)
        result.smtp_response = smtp_result.get('response', '')
        result.mailbox_valid = smtp_result.get('valid')
        result.smtp_time_ms = (datetime.now() - smtp_start).total_seconds() * 1000
        if smtp_result.get('catch_all'):
            result.catch_all_domain = True
        if smtp_result.get('error'):
            result.error_message = smtp_result['error']

        with self.stats_lock:
            if result.mailbox_valid is True:
                self.stats['smtp_valid'] += 1
            elif result.mailbox_valid is False:
                self.stats['smtp_invalid'] += 1
            else:
                self.stats['smtp_unreachable'] += 1

        if result.mailbox_valid is True:
            self._log(index, email, "SMTP", "OK", f"{result.smtp_response} | {result.smtp_time_ms:.0f}ms", Colors.GREEN)
        elif result.mailbox_valid is False:
            self._log(index, email, "SMTP", "FAIL", f"{result.smtp_response} | {result.smtp_time_ms:.0f}ms", Colors.RED)
        else:
            self._log(index, email, "SMTP", "WARN", f"Unreachable: {result.error_message[:60]}", Colors.YELLOW)

        # ----- FINAL SCORE -----
        result.risk_score, result.risk_level = self.calculate_risk(result)
        
        risk_color = Colors.GREEN if result.risk_level == "LOW" else Colors.YELLOW if result.risk_level == "MEDIUM" else Colors.RED
        self._log(index, email, "DONE", "DONE", 
                  f"Risk: {result.risk_level} (Score: {result.risk_score}/10)", risk_color)

        with self.stats_lock:
            self.stats['completed'] += 1
            if result.risk_level == "LOW": self.stats['low'] += 1
            elif result.risk_level == "MEDIUM": self.stats['medium'] += 1
            else: self.stats['high'] += 1

        return result


# ============================================================
# CSV DATA
# ============================================================

EMAIL_DATA = """#	Name	Organization	Email
1	Eunice	Africa AI Village (Qhala Trust)	eunice.mwangi@qhala.com
2	Shailendra	AKIS TECH. LIMITED (Russian Pavilion - Russoft)	shailendranjaiswal@gmail.com
3	Joseph	Andhra Pradesh Technology Services Limited	kollabathula.joseph@pwc.com
4	Manoj	Apisod Technologies Private Limited	manoj@complianceforindia.com
5	Jenna	Apolitical.co	joel.smith@apolitical.co
6	Reshu	AWS/Amazon	reshunat@amazon.com
7	Adil	Bharat1.ai	adil@nextchapter.co.in
8	Yera	Kgraph AI Solutions Private Limited	yera@myblue.ai
9	Arpan	Bluemachines (Apna.com)	arpan.khosla@apna.co
10	Anjul	CBS INFORMATION SYSYEMS INC	anjul.katare@gmail.com
11	Anurag	Central Bureau of Communication (MIB)	avproduction-cbc@gov.in
12	Jai	Centre for Development of Telematics (C-DOT)	head-mktg@cdot.in
13	David	Centre for Open Societal Systems (COSS) by IIIT-Bangalore (EkStep Foundation)	david@peopleplus.ai
14	Parv	Chattisgarh State Industrial Development Corporation	csidc.cg@gov.in
15	Nupura	CivicDataLab Private Limited	design@civicdatalab.in
16	Nilesh	N9M AI VENTURES	n.s.kadam@gmail.com
17	Maitreyie	CloudPe	marketing@leapswitch.com
18	Gurmeet	CommScope Inc	sgurmeet022@gmail.com
19	Kanupriya	Constl	kanupriya.jain@spaceworld.in
20	Sai	Cybersecurity NxxT Private Limited	sai.sundarakrishna@gmail.com
21	Abhishek	Dayananda Sagar University	cmo@dsu.edu.in
22	Prashant	Department of IT & Electronics, Goa	ceo-sitpc@goa.gov.in
23	K	Department of IT, Govt. of Assam	gopinath.narayan@gmail.com
24	Baishali	Digital India Bhashini Division	baishali.dibd@gmail.com
25	Sarvjeet	DRDO	cs.sanchit@gmail.com
26	Vikash	Electronics And Computer Software Export	vgupta@escindia.com
27	Vikash	Electronics And Computer Software Export	info@escindia.com
28	Mageswar	Electronics Corporation Of Tamil Nadu Limited	vpfacilitation@elcot.in
29	IFTEKHAR	ERA EDUCATION TRUST	iftekhar@elmcindia.org
30	CA	Unlock Future Fintech Private Limited	parag@fairvaluation.com
31	Muneender	Kenpath Technologies Private Limited	muneender@kenpath.io
32	Maninder	Gautam Solar Private Limited	marketing4@gautamsolar.com
33	Aditi	Government of Maharashtra	sec.it@maharashtra.gov.in
34	Navneet	Government of Uttar Pradesh	navneet.joshi@kpmg.com
35	Haider	Government of West Bengal	director.aicoe@wb.gov.in
36	Arshi	Grand Challenges India - BIRAC	pmubmgf1.birac@nic.in
37	Rahul	Hewlett Packard Enterprise (HPE)	rahul.luthra@shobizhavas.com
38	Thangakumar	Hindustan Institute Of Technology And Science	associatedeancs@hindustanuniv.ac.in
39	Nitin	HP India	nitinvinaik@gmail.com
40	Yogesh	IIT Gandhinagar	yk.meena@iitgn.ac.in
41	Dipyaman	IIT Kharagpur Ai4icps I Hub Foundation	ceo@ai4icps.in
42	Vimal	iMerit Technology	vimal.p@imerit.net
43	Maj	Indian Army (DGIS)	eswar.creator96@gmail.com
44	Archak	Indian Institute of Technology Bombay	archak@iitb.ac.in
45	Sethuram	Indian Institute Of Technology Madras	events@dsai.iitm.ac.in
46	Cmdr.Roopesh	Indian Navy	83aqua@gmail.com
47	Shivani	INDO GERMAN CHAMBER OF COMMERCE	shivani.chaturvedi@indo-german.com
48	Rajan	Indreni Resecurity Pvt. Ltd.	rajan.pant@resecurity.com
49	Gargi	Indus IntelliRisk and IntelliSense Services Pvt Ltd.	gargi.bhardwaj@iirisconsulting.com
50	Suyog	Infosys Limited	suyog.shetty@infosys.com
51	Saurabh	Innefu Labs Limited	saurabh.mathur@innefu.com
52	J.P	Innovation Hub UP Foundation AKTU	innovationhub@aktu.ac.in
53	Rohan	Integra Micro Systems	rohanshetty@integramicro.com
54	Saloni	Shobiz Experiential (Intel)	salonix.singhal@intel.com
55	Rajwant	Intellect Design Arena Limited	rajwant.kaur@intellectdesign.com
56	Aditya	Intensity Global Technologies Limited	aditya@igtpl.co.in
57	Sakshi	Invincible Ocean	sakshi@invincibleocean.com
58	Sonali	Ishan Infotech Limited	k.sonali@ishantechnologies.com
59	Aman	Istreet Network Limited	aman.singh@thirty9studio.com
60	Palak	Italian Trade Agency (Embassy of Italy)	p.sahni.ext@ice.it
61	Archi	Haptik	archi@haptik.co
62	Anvita	Jio Institute	anvita.mahajan@ril.com
63	Ruchika	Josh Talks Data	ruchikalalla@joshtalks.com
64	Vinayak	Karmayogi Bharat-DoPT	vinayakyp.kb@karmayogi.in
65	Gurunath	Karnataka Pavilion (IT&BT)	pd-aiml@karnataka.gov.in
66	Suneetha	N-Kor Private Limited (Kavion.ai)	suneetha.vegasana@kavion.ai
67	Sandip	Kerala State IT Mission	nishanthsr@gmail.com
68	Bonny	Trestle Labs Private Limited	bonny@trestlelabs.com
69	Trupti	Knight Fintech Private Limited	trupti.suthar@knightfintech.com
70	Sarthak	Kreativespace	sarthak.agarwal@avinyaaedtech.com
71	Tinu	Kyndryl Solutions Pvt Ltd	tinu.thomas@kyndryl.com
72	Akhilesh	Larsen & Toubro Limited	akhilesh.yadav3@larsentoubro.com
73	Dheeraj	Yo Doozy! Media Private Limited	dheeraj@yodoozymedia.com
74	Madhusudan	Lenovo	mjorapur@lenovo.com
75	Saakar	Lexlegis Solutions Private Limited	cmd@lexlegis.ai
76	Tejasie	Linkedin	temendonca@linkedin.com
77	Sheenu	The LNM Institute of Information Technology, Jaipur	sheenu.jain@lnmiit.ac.in
78	Tanushree	Lords Education (Wadhwani AI)	tanushree@wadhwaniai.org
79	Amit	Lovely International Trust	amit.jain1@lpu.co.in
80	Awantika	MP State Electronics Development Corp	ipcell-mp@mpsedc.com
81	Varun	MasterCard	varun.sakhuja@mastercard.com
82	Sushil	Meerut Institute of Engineering & Technology	sushil.sharma@miet.ac.in
83	Debdoot	Meesho	debdoot.mukherjee@meesho.com
84	Samadhan	Meganet Technologies Global Limited	samadhan.s@meganet1.com
85	Biren	Meghalaya Information Technology Societies	birentiwari@gmail.com
86	Anish	MeiTy	anish.somani@stpi.in
87	Sandeep	Microsoft Corporation (India) Private Limited	saurora@microsoft.com
88	Sanjay	Netsutra(miiStack)	sanjay.jindal@netsutra.com
89	Ashish	Minaions Private Limited	ashish@yugasa.com
90	Ravi	Ministry of Agriculture	ravir.singh@gov.in
91	Naman	Ministry Of Ayush	ayush-grid@gov.in
92	R	Ministry of Earth Sciences (IITM)	rphani@tropmet.res.in
93	Shakti	Ministry of Education	bharatinnovates-2026@gov.in
94	Rajalakshmi	Ministry of Health & Family Welfare	rdas@wjcf.in
95	Sumit	Ministry Of Panchayati Raj	sumittyagi31@gmail.com
96	Rakesh	Ministry of Rural Development	ssglab01@gmail.com
97	Neeraj	Ministry of Skill Development	neerajsurendran.dad@hub.nic.in
98	Siddharth	Ministry of Steel	bharat-steel@gov.in
99	Shuhrat	Ministry of Tajikistan (Zypl Holding)	shuhrat@qulla.ai
100	Mithun	Ministry of Tribal Affairs	mithun.c2191@gmail.com
101	Vinayak	Mio AI (NoPaperForms)	vinayak.s@meritto.com
102	PANKAJ	Mirror Security Private Limited	pankaj@mirrorsecurity.io
103	Aditya	MobilePe Fintech Private Limited	alliances@mobilepefintech.com
104	Hena	Nasscom	hena@nasscom.in
105	Aakash	National Payments Corporation Of India (NPCI)	aakash.poojary@npci.org.in
106	Divya	NCPEDP	divya_george@ncpedp.org
107	Shashwat	Neevai Supercloud Private Limited	sj@neevcloud.com"""


def parse_csv_data(data: str) -> list:
    entries = []
    lines = data.strip().split('\n')
    for line in lines[1:]:
        parts = line.split('\t')
        if len(parts) >= 4:
            idx = int(parts[0].strip())
            name = parts[1].strip()
            org = parts[2].strip()
            email = parts[3].strip()
            entries.append((idx, name, org, email))
    return entries


def print_header():
    """Print a clean header"""
    print()
    print("=" * 100)
    print(f"{Colors.BOLD}{Colors.CYAN}  EMAIL VERIFICATION TOOL â€” LIVE LOGGING{Colors.RESET}")
    print(f"  {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  |  Workers: {MAX_WORKERS}  |  Total: 107 emails")
    print("=" * 100)
    print(f"{Colors.GRAY}  LEGEND:  {Colors.GREEN}âœ… OK{Colors.GRAY}  {Colors.YELLOW}âš ï¸ WARN{Colors.GRAY}  {Colors.RED}âŒ FAIL{Colors.GRAY}  {Colors.CYAN}â„¹ï¸ INFO{Colors.GRAY}  {Colors.MAGENTA}ðŸ DONE{Colors.RESET}")
    print("-" * 100)
    print()


def print_summary(verifier: EmailVerifier, results: list, elapsed_sec: float):
    """Print summary report."""
    s = verifier.stats
    print()
    print("=" * 100)
    print(f"{Colors.BOLD}{Colors.CYAN}  VERIFICATION COMPLETE{Colors.RESET}")
    print("=" * 100)
    print()
    print(f"  â±ï¸  Total time: {elapsed_sec:.1f}s  ({elapsed_sec/107:.1f}s per email)")
    print(f"  ðŸ“§ Total emails: {len(results)}")
    print()
    
    # Layer breakdown
    print(f"  {Colors.BOLD}--- LAYER BREAKDOWN ---{Colors.RESET}")
    print(f"  {Colors.RED}âŒ Syntax failures:{Colors.RESET}  {s['syntax_fail']}")
    print(f"  {Colors.RED}âŒ DNS/MX failures:{Colors.RESET}  {s['dns_fail']}")
    print(f"  {Colors.GREEN}âœ… SMTP valid:{Colors.RESET}       {s['smtp_valid']}")
    print(f"  {Colors.RED}âŒ SMTP invalid:{Colors.RESET}     {s['smtp_invalid']}")
    print(f"  {Colors.YELLOW}âš ï¸  SMTP unreachable:{Colors.RESET}  {s['smtp_unreachable']}")
    print()
    
    # Risk breakdown
    print(f"  {Colors.BOLD}--- FINAL RISK SCORES ---{Colors.RESET}")
    print(f"  {Colors.GREEN}ðŸŸ¢ LOW RISK (1-3):{Colors.RESET}     {s['low']} emails â€” Safe to send")
    print(f"  {Colors.YELLOW}ðŸŸ¡ MEDIUM RISK (4-6):{Colors.RESET}  {s['medium']} emails â€” Monitor closely")
    print(f"  {Colors.RED}ðŸ”´ HIGH RISK (7-10):{Colors.RESET}    {s['high']} emails â€” DO NOT SEND")
    print()
    
    # HIGH risk list
    high_risk = [r for r in results if r.risk_level == "HIGH"]
    if high_risk:
        print(f"  {Colors.RED}{Colors.BOLD}ðŸ”´ HIGH RISK â€” SUPPRESS THESE:{Colors.RESET}")
        for r in high_risk:
            reason = r.error_message or f"Score {r.risk_score}"
            flags = []
            if r.free_provider: flags.append("Gmail")
            if r.role_based: flags.append("Role-based")
            if r.catch_all_domain: flags.append("Catch-all")
            if r.disposable: flags.append("Disposable")
            flag_str = f" [{', '.join(flags)}]" if flags else ""
            print(f"     #{r.index:<4} {r.email:<50} Score: {r.risk_score}  â†’ {reason}{flag_str}")
        print()

    print("=" * 100)


def save_json_report(results: list, filename: str = "email_verification_report.json"):
    report = []
    for r in results:
        report.append({
            "index": r.index, "name": r.name, "organization": r.organization,
            "email": r.email, "syntax_valid": r.syntax_valid,
            "domain_exists": r.domain_exists, "mx_found": r.mx_found,
            "mx_records": r.mx_records, "smtp_response": r.smtp_response,
            "mailbox_valid": r.mailbox_valid, "catch_all_domain": r.catch_all_domain,
            "disposable": r.disposable, "free_provider": r.free_provider,
            "role_based": r.role_based, "risk_level": r.risk_level,
            "risk_score": r.risk_score, "error_message": r.error_message,
            "dns_time_ms": r.dns_time_ms, "smtp_time_ms": r.smtp_time_ms,
            "verified_at": r.verified_at
        })
    with open(filename, 'w') as f:
        json.dump(report, f, indent=2)
    print(f"\nðŸ“ Full report: {filename}")


def export_sendable_csv(results: list, filename: str = "safe_to_send.csv"):
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['#', 'Name', 'Organization', 'Email', 'Risk Level', 'Risk Score'])
        for r in results:
            if r.risk_level in ('LOW', 'MEDIUM'):
                writer.writerow([r.index, r.name, r.organization, r.email, r.risk_level, r.risk_score])
    safe_count = sum(1 for r in results if r.risk_level in ('LOW', 'MEDIUM'))
    print(f"ðŸ“§ Safe-to-send: {filename} ({safe_count} emails)")


def export_do_not_send_csv(results: list, filename: str = "do_not_send.csv"):
    high_risk = [r for r in results if r.risk_level == 'HIGH']
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['#', 'Name', 'Organization', 'Email', 'Risk Level', 'Risk Score', 'Error'])
        for r in high_risk:
            writer.writerow([r.index, r.name, r.organization, r.email, r.risk_level, r.risk_score, r.error_message])
    count = len(high_risk)
    if count > 0:
        print(f"ðŸš« Do-not-send: {filename} ({count} emails)")
    else:
        print(f"ðŸš« Do-not-send: {filename} (0 emails â€” all clear!)")


# ============================================================
# MAIN
# ============================================================

def main():
    entries = parse_csv_data(EMAIL_DATA)
    verifier = EmailVerifier()
    verifier.stats['total'] = len(entries)
    results = []

    print_header()

    t_overall_start = datetime.now()

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {
            executor.submit(verifier.verify_email, idx, name, org, email): idx
            for idx, name, org, email in entries
        }

        for future in as_completed(futures):
            result = future.result()
            results.append(result)

    results.sort(key=lambda r: r.index)
    elapsed = (datetime.now() - t_overall_start).total_seconds()

    print_summary(verifier, results, elapsed)

    # Export files
    save_json_report(results)
    export_sendable_csv(results)
    export_do_not_send_csv(results)

    print(f"\n{Colors.GREEN}{Colors.BOLD}âœ… All done!{Colors.RESET}\n")


if __name__ == "__main__":
    main()