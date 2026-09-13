#!/usr/bin/env python3
"""Generates the Phodex design-canvas artboards (.dc.html) from the app's real
tokens (mobile/lib/shared/theme) and shared kit (stitch_ui.dart), so the canvas
matches the Flutter app pixel-for-pixel. Re-run after editing, then re-seed.
"""

from __future__ import annotations

import json
from pathlib import Path

OUT = Path(__file__).resolve().parent

# --- Tokens lifted from mobile/lib/shared/theme/app_colors.dart --------------
PALETTES = {
    "light": {
        "bg": "#FBF9F7", "surface": "#FFFFFF", "card": "#FFFFFF", "input": "#F5F3EF",
        "text": "#1D1A22", "text2": "#67616F", "muted": "#96909C", "border": "#EAE6E9",
        "accent": "#5B4FE8", "accentDeep": "#433AC4", "accentSoft": "#EEECFC",
        "success": "#16A34A", "warning": "#D97706", "error": "#DC2626",
        "onAccent": "#FFFFFF", "shadow": "rgba(0,0,0,0.06)", "shadowStrong": "rgba(0,0,0,0.12)",
        "successSoft": "rgba(22,163,74,0.12)", "warningSoft": "rgba(217,119,6,0.12)",
        "errorSoft": "rgba(220,38,38,0.12)", "accentTint": "rgba(91,79,232,0.12)",
        "dockBg": "rgba(255,255,255,0.78)",
    },
    "dark": {
        "bg": "#17151C", "surface": "#1D1B24", "card": "#221F2A", "input": "#28242F",
        "text": "#F5F3F7", "text2": "#A79FB0", "muted": "#716A7D", "border": "#322D3B",
        "accent": "#8B7FFF", "accentDeep": "#6C5FE0", "accentSoft": "#2C2650",
        "success": "#34D399", "warning": "#F3A73F", "error": "#F16565",
        "onAccent": "#FFFFFF", "shadow": "rgba(0,0,0,0.40)", "shadowStrong": "rgba(0,0,0,0.60)",
        "successSoft": "rgba(52,211,153,0.18)", "warningSoft": "rgba(243,167,63,0.18)",
        "errorSoft": "rgba(241,101,101,0.18)", "accentTint": "rgba(139,127,255,0.18)",
        "dockBg": "rgba(29,27,36,0.78)",
    },
}
TERMINAL = {"bg": "#17151C", "text": "#E6E2EC", "muted": "#8E8798"}
SANS = "'IBM Plex Sans', 'Helvetica Neue', Arial, sans-serif"
SERIF = "'Fraunces', Georgia, 'Times New Roman', serif"
MONO = "'IBM Plex Mono', Menlo, Consolas, monospace"
FONT_LINK = (
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
    'family=Fraunces:opsz,wght@9..144,600&family=IBM+Plex+Sans:wght@400;500;600;700'
    '&family=IBM+Plex+Mono:wght@400;500&display=swap">'
)

# type ladder (app_typography.dart)
T = {
    "micro": "font-size: 11px; line-height: 14px; font-weight: 700; letter-spacing: 0.8px; text-transform: uppercase;",
    "caption": "font-size: 13px; line-height: 18px; font-weight: 400;",
    "captionM": "font-size: 13px; line-height: 18px; font-weight: 500;",
    "bodySmall": "font-size: 15px; line-height: 22px; font-weight: 400;",
    "label": "font-size: 15px; line-height: 20px; font-weight: 600;",
    "body": "font-size: 17px; line-height: 25px; font-weight: 400;",
    "titleM": "font-size: 17px; line-height: 24px; font-weight: 600;",
    "subhead": "font-size: 20px; line-height: 26px; font-weight: 600; letter-spacing: -0.3px;",
    "title": "font-size: 24px; line-height: 30px; font-weight: 600; letter-spacing: -0.4px;",
}
MAC_NAME = "Gaurav's Mac"
ERR_TITLE = "Something didn't load"
UNREACHABLE = "Couldn't reach your runtime."
CANCELLED_MSG = "Couldn't reach that address. Make sure your desktop is running Phodex and you're on the same network or Tailscale."
R = {"chip": 12, "button": 18, "global": 20, "card": 24, "input": 24, "sheet": 28, "pill": 999}


# --- Mascot (original robin, geometry from mobile/lib/shared/widgets/phodex_mascot.dart)
def mascot(size: int, mood: str = "idle") -> str:
    brows = "1" if mood in ("curious", "error") else "0"
    smile = "1" if mood == "success" else "0"
    pupil = "9.6" if mood == "curious" else "7.7"
    dx, dy = (3, -3) if mood == "thinking" else (0, 0)
    dot_anim = 'style="animation: pulse 1.1s ease-in-out infinite alternate;"' if mood == "thinking" else ""
    eye_open = "" if mood != "resting" else "opacity=\"0\""
    closed = (
        '<path d="M76 98Q88.8 106 101.6 98" stroke="#241A12" stroke-width="3" stroke-linecap="round" fill="none"/>'
        '<path d="M138.4 98Q151.2 106 164 98" stroke="#241A12" stroke-width="3" stroke-linecap="round" fill="none"/>'
        if mood == "resting" else ""
    )
    wing_raise = "M43.2 120Q-4.8 100 19.2 150Q38.4 150 43.2 177.6Z" if mood == "success" else "M43.2 120Q4.8 139.2 19.2 187.2Q38.4 168 43.2 177.6Z"
    wing_raise_r = "M196.8 120Q244.8 100 220.8 150Q201.6 150 196.8 177.6Z" if mood == "success" else "M196.8 120Q235.2 139.2 220.8 187.2Q201.6 168 196.8 177.6Z"
    brow_l = "M84 70Q96 62 108 70" if mood == "error" else "M84 66Q96 60 108 66"
    brow_r = "M132 70Q144 62 156 70" if mood == "error" else "M132 66Q144 60 156 66"
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 240 240" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Phodex robin, {mood}">'
        f'<path d="{wing_raise}" fill="#362619"/><path d="{wing_raise_r}" fill="#362619"/>'
        '<rect x="28.8" y="43.2" width="182.4" height="172.8" rx="81.6" fill="#463222"/>'
        '<rect x="64.8" y="115.2" width="110.4" height="96" rx="52.8" fill="#E2572B"/>'
        '<path d="M105.6 48L120 28.8L134.4 48Z" fill="#362619"/><circle cx="120" cy="28.8" r="6.7" fill="#5B4FE8" {dot_anim}/>'
        '<path d="M103.2 122.4L136.8 122.4L120 133.2Z" fill="#F4A93E"/>'
        f'<g {eye_open}><circle cx="88.8" cy="98.4" r="14.4" fill="#FBF9F7"/><circle cx="{88.8 + dx}" cy="{98.4 + dy}" r="{pupil}" fill="#241A12"/>'
        f'<circle cx="151.2" cy="98.4" r="14.4" fill="#FBF9F7"/><circle cx="{151.2 + dx}" cy="{98.4 + dy}" r="{pupil}" fill="#241A12"/></g>{closed}'
        f'<path d="{brow_l}" stroke="#362619" stroke-width="2.5" stroke-linecap="round" fill="none" opacity="{brows}"/>'
        f'<path d="{brow_r}" stroke="#362619" stroke-width="2.5" stroke-linecap="round" fill="none" opacity="{brows}"/>'
        f'<path d="M100 106Q120 116 140 106" stroke="#241A12" stroke-width="2.5" stroke-linecap="round" fill="none" opacity="{smile}"/>'
        "</svg>"
    )


def icon(name: str, size: int = 20, color: str = "currentColor") -> str:
    paths = {
        "back": '<path d="M15 5l-7 7 7 7"/>',
        "bell": '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
        "folder": '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
        "chevron": '<path d="M9 6l6 6-6 6"/>',
        "down": '<path d="M6 9l6 6 6-6"/>',
        "send": '<path d="M12 19V5"/><path d="M5 12l7-7 7 7"/>',
        "stop": '<rect x="7" y="7" width="10" height="10" rx="2" fill="currentColor" stroke="none"/>',
        "cloud": '<path d="M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9a4.5 4.5 0 0 1-.5 9z"/>',
        "laptop": '<rect x="3" y="5" width="18" height="12" rx="2"/><path d="M2 20h20"/>',
        "qr": '<rect x="4" y="4" width="6" height="6"/><rect x="14" y="4" width="6" height="6"/><rect x="4" y="14" width="6" height="6"/><path d="M14 14h3v3M20 14v6h-6"/>',
        "check": '<path d="M5 12l5 5L20 7"/>',
        "x": '<path d="M6 6l12 12M18 6L6 18"/>',
        "info": '<circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v5h1"/>',
        "warn": '<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17h.01"/>',
        "refresh": '<path d="M20 12a8 8 0 1 1-2.3-5.7"/><path d="M20 4v5h-5"/>',
        "task": '<rect x="5" y="4" width="14" height="16" rx="2"/><path d="M9 9h6M9 13h6M9 17h3"/>',
        "user": '<circle cx="12" cy="8" r="4"/><path d="M4 20a8 8 0 0 1 16 0"/>',
        "git": '<circle cx="6" cy="6" r="2"/><circle cx="6" cy="18" r="2"/><circle cx="18" cy="8" r="2"/><path d="M6 8v8M18 10a6 6 0 0 1-6 6H8"/>',
        "terminal": '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 10l3 2-3 2M12 15h5"/>',
        "edit": '<path d="M4 20h4l10-10-4-4L4 16z"/>',
        "sparkle": '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/>',
        "key": '<circle cx="8" cy="14" r="4"/><path d="M11 11l9-9M16 6l3 3"/>',
        "eye": '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    }
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{color}" '
        f'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{paths[name]}</svg>'
    )


# --- Kit pieces (stitch_ui.dart) -------------------------------------------
def header(title: str | None = None, back: bool = False, bell: bool = True, badge: bool = False, trailing: str = "", mood: str = "idle") -> str:
    left = (
        f'<div style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; color: {{{{c.accent}}}};">{icon("back", 22)}</div>'
        if back else f'<div style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;">{mascot(40, mood)}</div>'
    )
    mid = (
        f'<div style="flex-grow: 1; font-family: {SERIF}; font-size: 28px; line-height: 34px; font-weight: 600; letter-spacing: -0.6px; color: {{{{c.text}}}}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">{title}</div>'
        if title else '<div style="flex-grow: 1;"></div>'
    )
    if trailing:
        right = trailing
    elif bell:
        dot = f'<span style="position: absolute; top: 10px; right: 10px; width: 7px; height: 7px; border-radius: 999px; background: {{{{c.error}}}};"></span>' if badge else ""
        right = f'<div style="position: relative; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; color: {{{{c.text}}}};">{icon("bell", 26)}{dot}</div>'
    else:
        right = ""
    return f'<div style="display: flex; align-items: center; gap: 12px; height: 56px;">{left}{mid}{right}</div>'


def dock(active: str) -> str:
    items = [("home", "Agents"), ("activity", "Tasks"), ("repos", "Repos"), ("account", "Account")]
    cells = []
    for key, label in items:
        color = "{{c.accent}}" if key == active else "{{c.text2}}"
        glyph = mascot(24, "idle") if key == "home" else icon({"activity": "task", "repos": "folder", "account": "user"}[key], 24, color)
        cells.append(
            f'<div style="flex-grow: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; color: {color};">{glyph}'
            f'<span style="font-family: {SANS}; font-size: 11px; line-height: 14px; font-weight: 700; color: {color};">{label}</span></div>'
        )
    return (
        f'<div style="position: absolute; left: 0; right: 0; bottom: 0; height: 116px; pointer-events: none; '
        f'background: linear-gradient(to bottom, transparent 0%, {{{{c.bg}}}} 62%);"></div>'
        f'<div style="position: absolute; left: 20px; right: 20px; bottom: 16px; height: 72px; border-radius: 999px; '
        f'background: {{{{c.dockBg}}}}; backdrop-filter: blur(24px); border: 1px solid {{{{c.surface}}}}; '
        f'box-shadow: 0 10px 26px {{{{c.shadowStrong}}}}; display: flex; align-items: stretch; padding: 0 8px;">{"".join(cells)}</div>'
    )


def card(inner: str, padding: int = 20, extra: str = "") -> str:
    return (
        f'<div style="background: {{{{c.card}}}}; border-radius: {R["card"]}px; padding: {padding}px; '
        f'box-shadow: 0 5px 24px {{{{c.shadow}}}}; {extra}">{inner}</div>'
    )


def primary_button(label: str, ic: str | None = None, disabled: bool = False) -> str:
    op = "opacity: 0.4;" if disabled else ""
    i = icon(ic, 20, "{{c.onAccent}}") if ic else ""
    return (
        f'<div style="height: 58px; border-radius: {R["button"]}px; background: {{{{c.accent}}}}; color: {{{{c.onAccent}}}}; '
        f'display: flex; align-items: center; justify-content: center; gap: 8px; font-family: {SANS}; font-size: 17px; font-weight: 700; {op}">{i}{label}</div>'
    )


def secondary_button(label: str, ic: str | None = None) -> str:
    i = icon(ic, 20, "{{c.text}}") if ic else ""
    return (
        f'<div style="height: 58px; border-radius: {R["button"]}px; border: 1px solid {{{{c.border}}}}; color: {{{{c.text}}}}; '
        f'display: flex; align-items: center; justify-content: center; gap: 8px; font-family: {SANS}; font-size: 17px; font-weight: 700;">{i}{label}</div>'
    )


def text_button(label: str, color: str = "{{c.accent}}") -> str:
    return f'<div style="height: 48px; display: flex; align-items: center; justify-content: center; font-family: {SANS}; {T["label"]} color: {color};">{label}</div>'


def status_chip(status: str, compact: bool = False, pulse: bool = False) -> str:
    color, soft, label = {
        "completed": ("{{c.success}}", "{{c.successSoft}}", "Completed"),
        "waiting_approval": ("{{c.warning}}", "{{c.warningSoft}}", "Needs approval"),
        "failed": ("{{c.error}}", "{{c.errorSoft}}", "Failed"),
        "cancelled": ("{{c.muted}}", "{{c.input}}", "Cancelled"),
        "running": ("{{c.accent}}", "{{c.accentTint}}", "Running"),
        "queued": ("{{c.accent}}", "{{c.accentTint}}", "Queued"),
    }[status]
    pad = "4px 8px" if compact else "6px 12px"
    size = T["captionM"] if compact else T["label"]
    anim = "animation: pulse 1.1s ease-in-out infinite alternate;" if pulse else ""
    return (
        f'<span style="display: inline-flex; align-items: center; gap: 8px; padding: {pad}; border-radius: 999px; background: {soft};">'
        f'<span style="width: 8px; height: 8px; border-radius: 999px; background: {color}; {anim}"></span>'
        f'<span style="font-family: {SANS}; {size} color: {color};">{label}</span></span>'
    )


def context_pill(name: str, branch: str | None = None, emphasized: bool = False, tappable: bool = True) -> str:
    fg = "{{c.accentDeep}}" if emphasized else "{{c.text2}}"
    bg = "{{c.accentSoft}}" if emphasized else "{{c.input}}"
    text = name if not branch else f"{name} · {branch}"
    chev = icon("down", 16, fg) if tappable else ""
    return (
        f'<span style="display: inline-flex; align-items: center; gap: 8px; padding: 8px 12px; border-radius: 999px; background: {bg}; max-width: 100%;">'
        f'{icon("folder", 16, fg)}<span style="font-family: {SANS}; {T["captionM"]} color: {fg}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">{text}</span>{chev}</span>'
    )


def banner(message: str, tone: str = "info", action: str | None = None, busy: bool = False) -> str:
    color, soft, ic = {
        "info": ("{{c.accent}}", "{{c.accentTint}}", "info"),
        "success": ("{{c.success}}", "{{c.successSoft}}", "check"),
        "warning": ("{{c.warning}}", "{{c.warningSoft}}", "warn"),
        "error": ("{{c.error}}", "{{c.errorSoft}}", "warn"),
    }[tone]
    lead = (
        f'<span style="width: 16px; height: 16px; border-radius: 999px; border: 2px solid {color}; border-top-color: transparent; animation: spin 0.9s linear infinite;"></span>'
        if busy else icon(ic, 18, color)
    )
    act = f'<span style="font-family: {SANS}; {T["label"]} color: {color}; padding: 0 12px;">{action}</span>' if action else ""
    return (
        f'<div style="display: flex; align-items: center; gap: 12px; padding: 12px 16px; border-radius: {R["button"]}px; background: {soft};">'
        f'{lead}<span style="flex-grow: 1; font-family: {SANS}; {T["caption"]} color: {{{{c.text}}}};">{message}</span>{act}</div>'
    )


def composer(hint: str, ctx: str = "", enabled: bool = True, running: bool = False, value: str = "") -> str:
    btn_bg = "{{c.error}}" if running else "{{c.accent}}"
    btn_op = "" if (enabled or running) else "opacity: 0.35;"
    btn_icon = icon("stop", 22, "{{c.onAccent}}") if running else icon("send", 22, "{{c.onAccent}}")
    text_color = "{{c.text}}" if value else "{{c.muted}}"
    return (
        f'<div style="background: {{{{c.card}}}}; border: 1px solid {{{{c.border}}}}; border-radius: {R["card"]}px; padding: 12px; box-shadow: 0 6px 24px {{{{c.shadow}}}}; display: flex; flex-direction: column; gap: 8px;">'
        + (f'<div style="padding-left: 4px;">{ctx}</div>' if ctx else "")
        + f'<div style="display: flex; align-items: flex-end; gap: 8px;">'
        f'<div style="flex-grow: 1; padding: 12px; font-family: {SANS}; {T["body"]} color: {text_color};">{value or hint}</div>'
        f'<div style="width: 48px; height: 48px; border-radius: 999px; background: {btn_bg}; display: flex; align-items: center; justify-content: center; {btn_op}">{btn_icon}</div>'
        "</div></div>"
    )


def empty_state(title: str, message: str, mood: str = "resting", action: str | None = None, secondary: str | None = None) -> str:
    a = f'<div style="margin-top: 24px; height: 48px; padding: 0 20px; border-radius: {R["button"]}px; background: {{{{c.accent}}}}; color: {{{{c.onAccent}}}}; display: inline-flex; align-items: center; font-family: {SANS}; {T["label"]}">{action}</div>' if action else ""
    s = f'<div style="margin-top: 8px;">{text_button(secondary)}</div>' if secondary else ""
    return (
        f'<div style="display: flex; flex-direction: column; align-items: center; text-align: center; padding: 0 32px;">{mascot(72, mood)}'
        f'<div style="margin-top: 20px; font-family: {SANS}; {T["subhead"]} color: {{{{c.text}}}};">{title}</div>'
        f'<div style="margin-top: 8px; font-family: {SANS}; {T["bodySmall"]} color: {{{{c.text2}}}};">{message}</div>{a}{s}</div>'
    )


def terminal_block(text: str, label: str | None = None) -> str:
    lab = f'<div style="font-family: {SANS}; {T["micro"]} color: {TERMINAL["muted"]}; margin-bottom: 8px;">{label}</div>' if label else ""
    return (
        f'<div style="background: {TERMINAL["bg"]}; border-radius: {R["button"]}px; padding: 16px; font-family: {MONO}; font-size: 13px; line-height: 18px; color: {TERMINAL["text"]}; white-space: pre-wrap; word-break: break-all;">{lab}{text}</div>'
    )


def section_label(text: str, trailing: str = "") -> str:
    return f'<div style="display: flex; align-items: center; margin-bottom: 12px;"><span style="flex-grow: 1; font-family: {SANS}; {T["micro"]} color: {{{{c.muted}}}};">{text.upper()}</span>{trailing}</div>'


def p(text: str, style: str = "body", color: str = "{{c.text2}}", extra: str = "") -> str:
    return f'<div style="font-family: {SANS}; {T[style]} color: {color}; {extra}">{text}</div>'


def hero(text: str, size: int = 40, color: str = "{{c.text}}", align: str = "center") -> str:
    return f'<div style="font-family: {SERIF}; font-size: {size}px; line-height: 1.05; font-weight: 600; letter-spacing: -0.8px; color: {color}; text-align: {align}; white-space: pre-line;">{text}</div>'


def phone(body: str, with_dock: str | None = None, bottom: str | None = None, pad_bottom: int = 24) -> str:
    """A 390×844 artboard with the theme tweak (light/dark) bound to every token."""
    pb = 128 if with_dock else pad_bottom
    dock_html = dock(with_dock) if with_dock else ""
    bottom_html = f'<div style="position: absolute; left: 0; right: 0; bottom: 0; padding: 12px 16px 24px; background: linear-gradient(to bottom, transparent, {{{{c.bg}}}} 30%);">{bottom}</div>' if bottom else ""
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  {FONT_LINK}
  <style>
    body {{ margin: 0; font-family: {SANS}; -webkit-font-smoothing: antialiased; }}
    a {{ color: #5B4FE8; }} a:hover {{ color: #433AC4; }}
    @keyframes pulse {{ from {{ opacity: 1; }} to {{ opacity: 0.4; }} }}
    @keyframes spin {{ to {{ transform: rotate(360deg); }} }}
  </style>
</helmet>
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; background: {{{{c.bg}}}}; border-radius: 0px;">
  <div style="position: absolute; inset: 0; overflow: hidden; padding: 16px 24px {pb}px; display: flex; flex-direction: column; gap: 0px;">
{body}
  </div>
  {dock_html}
  {bottom_html}
</div>
</x-dc>
<script data-dc-script data-props='{{"theme":{{"editor":"enum","options":["light","dark"],"default":"light","section":"Theme"}},"$preview":{{"width":390,"height":844}}}}'>
const PALETTES = {json.dumps(PALETTES)};
class Component extends DCLogic {{
  renderVals() {{
    const theme = this.props.theme === 'dark' ? 'dark' : 'light';
    return {{ c: PALETTES[theme] }};
  }}
}}
</script>
</body>
</html>
"""


def gap(px: int) -> str:
    return f'<div style="height: {px}px; flex-shrink: 0;"></div>'


def spacer() -> str:
    return '<div style="flex-grow: 1;"></div>'


# --- Onboarding artboards ---------------------------------------------------
def welcome() -> str:
    bullets = [
        ("sparkle", "Start tasks from your phone", "Describe what you need built; an AI engineer does the work."),
        ("terminal", "Watch it happen live", "Every tool call and file change streams to you as it runs."),
        ("check", "Approve every change", "Nothing runs or pushes until you say so."),
    ]
    rows = "".join(
        f'<div style="display: flex; gap: 14px; align-items: flex-start;">'
        f'<div style="width: 40px; height: 40px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">{icon(i, 20, "{{c.accentDeep}}")}</div>'
        f'<div>{p(t, "titleM", "{{c.text}}")}{p(d, "caption")}</div></div>'
        for i, t, d in bullets
    )
    body = (
        spacer() + f'<div style="display: flex; justify-content: center;">{mascot(108)}</div>' + gap(40)
        + hero("Your AI engineer,\nin your pocket.", 38)
        + gap(16) + p("Start coding tasks, monitor live execution and safely approve changes from anywhere.", "body", "{{c.text2}}", "text-align: center;")
        + gap(40) + f'<div style="display: flex; flex-direction: column; gap: 20px;">{rows}</div>'
        + spacer() + primary_button("Get started") + gap(12)
        + p("Works with Phodex Cloud or your own laptop.", "caption", "{{c.muted}}", "text-align: center;")
    )
    return phone(body)


def runtime_choice() -> str:
    def option(ic: str, title: str, tag: str | None, desc: str, points: list[str], selected: bool) -> str:
        border = f'border: 2px solid {{{{c.accent}}}};' if selected else f'border: 2px solid transparent;'
        t = f'<span style="font-family: {SANS}; {T["micro"]} color: {{{{c.accentDeep}}}}; background: {{{{c.accentSoft}}}}; padding: 4px 8px; border-radius: 999px;">{tag}</span>' if tag else ""
        pts = "".join(f'<div style="display: flex; gap: 8px; align-items: center;">{icon("check", 16, "{{c.success}}")}{p(x, "caption", "{{c.text2}}")}</div>' for x in points)
        return card(
            f'<div style="display: flex; align-items: center; gap: 12px;"><div style="width: 44px; height: 44px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center;">{icon(ic, 22, "{{c.accentDeep}}")}</div>'
            f'<div style="flex-grow: 1; display: flex; align-items: center; gap: 8px;">{p(title, "subhead", "{{c.text}}")}{t}</div>{icon("chevron", 20, "{{c.muted}}")}</div>'
            f'{gap(12)}{p(desc, "bodySmall")}{gap(12)}<div style="display: flex; flex-direction: column; gap: 6px;">{pts}</div>',
            extra=border,
        )

    body = (
        header("Choose a runtime", back=True, bell=False) + gap(8)
        + p("You can change this any time from Account.", "bodySmall") + gap(20)
        + option("cloud", "Phodex Cloud", "Recommended", "A hosted runner clones any GitHub repository and works while your laptop is closed.",
                 ["Nothing to install", "Try the demo instantly", "Push with your GitHub token"], True)
        + gap(16)
        + option("laptop", "My desktop", None, "Pair your laptop over Wi-Fi or Tailscale. Tasks run on your own machine with the CLI you are logged into.",
                 ["Repos already on disk", "Your local git credentials"], False)
        + spacer() + primary_button("Continue with Phodex Cloud", "cloud")
    )
    return phone(body)


def connect_desktop() -> str:
    body = (
        header("Connect desktop", back=True, bell=False) + gap(8)
        + p("On your laptop, run the backend and open localhost:8000/pair. Scan the code it shows.", "bodySmall") + gap(24)
        + card(
            f'<div style="display: flex; flex-direction: column; align-items: center; gap: 16px;">'
            f'<div style="width: 96px; height: 96px; border-radius: {R["global"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center;">{icon("qr", 48, "{{c.accentDeep}}")}</div>'
            f'{p("Point the camera at the QR code on the pairing page.", "caption", "{{c.text2}}", "text-align: center;")}'
            f'<div style="align-self: stretch;">{primary_button("Scan QR code", "qr")}</div></div>'
        )
        + gap(16)
        + p("Or enter the address manually", "captionM", "{{c.muted}}", "text-align: center;") + gap(12)
        + f'<div style="height: 56px; border-radius: {R["input"]}px; background: {{{{c.input}}}}; display: flex; align-items: center; padding: 0 20px; font-family: {SANS}; {T["body"]} color: {{{{c.muted}}}};">http://100.64.0.12:8000</div>'
        + gap(12) + secondary_button("Test connection")
        + gap(20) + banner(CANCELLED_MSG, "error", "Help")
        + spacer()
        + text_button("Forget this desktop", "{{c.error}}")
    )
    return phone(body)


def sign_in() -> str:
    body = (
        header("Sign in", back=True, bell=False) + gap(16)
        + card(
            f'<div style="display: flex; align-items: center; gap: 12px;">'
            f'<div style="width: 44px; height: 44px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center;">{icon("cloud", 22, "{{c.accentDeep}}")}</div>'
            f'<div style="flex-grow: 1;">{p("Phodex Cloud", "titleM", "{{c.text}}")}<div style="display: flex; align-items: center; gap: 6px; margin-top: 2px;"><span style="width: 8px; height: 8px; border-radius: 999px; background: {{{{c.success}}}};"></span>{p("Online · demo available", "caption")}</div></div>'
            f'{text_button("Change")}</div>'
        )
        + spacer()
        + f'<div style="display: flex; justify-content: center;">{mascot(96, "curious")}</div>' + gap(28)
        + hero("Welcome back.", 34) + gap(12)
        + p("Sign in to keep your tasks, repositories and approvals in one place.", "bodySmall", "{{c.text2}}", "text-align: center;")
        + spacer()
        + banner("Sign-in was cancelled. Try again when you're ready.", "error")
        + gap(16) + primary_button("Continue with Google") + gap(12) + secondary_button("Try the demo", "sparkle")
        + gap(12) + p("By continuing you agree to the terms and privacy policy.", "caption", "{{c.muted}}", "text-align: center;")
    )
    return phone(body)


def first_repo() -> str:
    def field(label: str, value: str, placeholder: bool = True, ic: str | None = None) -> str:
        color = "{{c.muted}}" if placeholder else "{{c.text}}"
        i = icon(ic, 18, "{{c.muted}}") if ic else ""
        return (
            f'{p(label, "captionM", "{{c.text2}}")}{gap(6)}'
            f'<div style="height: 56px; border-radius: {R["input"]}px; background: {{{{c.input}}}}; display: flex; align-items: center; gap: 10px; padding: 0 20px; font-family: {SANS}; {T["body"]} color: {color};">{i}{value}</div>'
        )
    body = (
        header("Your first repo", back=True, bell=False) + gap(8)
        + p("Phodex Cloud clones it into a workspace and works there. Any GitHub repository you can access.", "bodySmall") + gap(24)
        + field("GitHub repository", "github.com/you/your-project", False, "git") + gap(16)
        + field("Branch (optional)", "main", True) + gap(16)
        + field("GitHub token (optional)", "Fine-grained token · Contents: read &amp; write", True, "key") + gap(8)
        + p("Stored encrypted. Needed to push; public repos clone without it.", "caption", "{{c.muted}}")
        + gap(24) + banner("Repositories are metadata-synced — there is no shell, file, or search access from your phone.", "info")
        + spacer() + primary_button("Connect repository", "git") + gap(8) + text_button("Skip for now", "{{c.text2}}")
    )
    return phone(body)


def notifications_step() -> str:
    rows = "".join(
        f'<div style="display: flex; gap: 14px; align-items: center;"><div style="width: 40px; height: 40px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">{icon(i, 20, "{{c.accentDeep}}")}</div><div>{p(t, "titleM", "{{c.text}}")}{p(d, "caption")}</div></div>'
        for i, t, d in [
            ("warn", "Approval needed", "Your agent is waiting on you before it runs a command."),
            ("check", "Task completed", "The work is done and ready to review."),
            ("x", "Task failed", "Something went wrong and needs a look."),
        ]
    )
    body = (
        header("", back=True, bell=False)
        + spacer() + f'<div style="display: flex; justify-content: center;">{mascot(108, "curious")}</div>' + gap(32)
        + hero("Know when\nyou're needed.", 34) + gap(16)
        + p("Phodex only sends a push when your input matters. No digests, no marketing.", "body", "{{c.text2}}", "text-align: center;")
        + gap(32) + f'<div style="display: flex; flex-direction: column; gap: 16px;">{rows}</div>'
        + spacer() + primary_button("Enable notifications", "bell") + gap(12) + secondary_button("Not now")
    )
    return phone(body)


def home_first_run() -> str:
    chips = "".join(
        f'<span style="padding: 8px 12px; border-radius: {R["chip"]}px; background: {{{{c.input}}}}; font-family: {SANS}; {T["captionM"]} color: {{{{c.text}}}}; white-space: nowrap;">{t}</span>'
        for t in ["Add tests for the auth module", "Fix the flaky CI job", "Write a README"]
    )
    body = (
        header(None, bell=True, badge=False) + gap(8)
        + hero("Good morning,\nGaurav.", 34, align="left") + gap(24)
        + banner("Phodex Cloud is online · phodex on main", "success")
        + gap(28)
        + empty_state("No tasks yet", "Describe what you need built and Phodex will get to work. Try one of these to start:", "curious")
        + gap(20)
        + f'<div style="display: flex; flex-wrap: wrap; gap: 8px;">{chips}</div>'
        + spacer()
        + composer("Describe what you need built…", context_pill("phodex", "main"), enabled=True)
    )
    return phone(body, with_dock="home")


# --- Screen artboards -------------------------------------------------------
def session() -> str:
    def trace(ic: str, title: str, meta: str, detail: str | None = None, tone: str = "muted") -> str:
        color = {"muted": "{{c.muted}}", "accent": "{{c.accent}}", "success": "{{c.success}}", "error": "{{c.error}}"}[tone]
        d = f'{gap(10)}{terminal_block(detail)}' if detail else ""
        return (
            f'<div style="display: flex; gap: 12px;">'
            f'<div style="width: 32px; height: 32px; border-radius: 999px; background: {{{{c.input}}}}; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">{icon(ic, 16, color)}</div>'
            f'<div style="flex-grow: 1; min-width: 0;"><div style="display: flex; justify-content: space-between; gap: 8px;">{p(title, "titleM", "{{c.text}}")}{p(meta, "caption", "{{c.muted}}")}</div>{d}</div></div>'
        )
    timeline = "".join([
        trace("sparkle", "Task started", "10:42"),
        trace("eye", "Read src/auth/session.py", "10:42"),
        trace("terminal", "Ran pytest -q tests/test_auth.py", "10:43", "12 passed in 1.8s", "success"),
    ])
    approval = card(
        f'<div style="display: flex; align-items: center; gap: 10px;">{icon("warn", 20, "{{c.warning}}")}{p("Allow bash?", "subhead", "{{c.text}}")}</div>{gap(8)}'
        f'{p("The agent wants to run a command in the cloud sandbox.", "bodySmall")}{gap(12)}'
        f'{terminal_block("git push -u origin feature/refresh-rotation", "command")}{gap(16)}'
        f'<div style="display: flex; gap: 12px;"><div style="flex-grow: 1;">{primary_button("Approve", "check")}</div><div style="flex-grow: 1;">{secondary_button("Reject")}</div></div>',
        extra=f"border: 1px solid {{{{c.warning}}}};",
    )
    body = (
        header("Rotate refresh tokens", back=True, bell=False) + gap(8)
        + f'<div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">{status_chip("waiting_approval", pulse=True)}{context_pill("phodex", "feature/refresh-rotation", tappable=False)}</div>'
        + gap(16) + banner("Reconnecting to live updates…", "warning", busy=True) + gap(20)
        + section_label("Trace") + f'<div style="display: flex; flex-direction: column; gap: 18px;">{timeline}</div>'
        + gap(20) + approval
    )
    return phone(body, bottom=composer("Reply to this task…", running=True), pad_bottom=140)


def approvals() -> str:
    def compact_item(title: str, task: str) -> str:
        return card(
            f'<div style="display: flex; align-items: center; gap: 10px;"><div style="width: 40px; height: 40px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center;">{icon("terminal", 20, "{{c.accentDeep}}")}</div>'
            f'<div style="flex-grow: 1; min-width: 0;">{p(title, "titleM", "{{c.text}}")}{p(task, "caption")}</div>{status_chip("waiting_approval", compact=True)}{icon("chevron", 20, "{{c.muted}}")}</div>'
        )

    def item(title: str, task: str, cmd: str, risk: str) -> str:
        return card(
            f'<div style="display: flex; align-items: center; gap: 10px;"><div style="width: 40px; height: 40px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center;">{icon("terminal", 20, "{{c.accentDeep}}")}</div>'
            f'<div style="flex-grow: 1; min-width: 0;">{p(title, "titleM", "{{c.text}}")}{p(task, "caption")}</div></div>{gap(12)}'
            f'<div style="display: flex; gap: 8px; align-items: center;">{status_chip("waiting_approval", compact=True)}<span style="padding: 4px 8px; border-radius: 999px; background: {{{{c.input}}}}; font-family: {SANS}; {T["captionM"]} color: {{{{c.text2}}}};">Risk · {risk}</span></div>{gap(12)}'
            f'{terminal_block(cmd, "command · /workspace/phodex")}{gap(16)}'
            f'<div style="display: flex; gap: 12px;"><div style="flex-grow: 1;">{primary_button("Approve", "check")}</div><div style="flex-grow: 1;">{secondary_button("Reject")}</div></div>{gap(4)}'
            f'{text_button("View full execution plan")}'
        )
    body = (
        header("Approvals", back=True, trailing=f'<div style="width: 48px; height: 48px; display: flex; align-items: center; justify-content: center; color: {{{{c.text}}}};">{icon("refresh", 22)}</div>') + gap(8)
        + card(
            f'<div style="display: flex; align-items: center; gap: 16px;"><div style="font-family: {SERIF}; font-size: 40px; line-height: 1; font-weight: 600; color: {{{{c.text}}}};">2</div>'
            f'<div>{p("pending approvals", "titleM", "{{c.text}}")}{p("Approvals are gated on your phone — nothing runs until you say so.", "caption")}</div></div>'
        )
        + gap(16)
        + item("Allow bash?", "Rotate refresh tokens", "pytest -q tests/", "medium")
        + gap(16)
        + compact_item("Allow bash?", "Add CHANGELOG")
    )
    return phone(body)


def repos() -> str:
    def repo(name: str, branch: str, path: str, active: bool, cloud: bool) -> str:
        badge = f'<span style="padding: 4px 8px; border-radius: 999px; background: {{{{c.accentSoft}}}}; font-family: {SANS}; {T["captionM"]} color: {{{{c.accentDeep}}}};">Cloud</span>' if cloud else ""
        action = (
            f'<span style="padding: 8px 12px; border-radius: 999px; background: {{{{c.successSoft}}}}; font-family: {SANS}; {T["captionM"]} color: {{{{c.success}}}};">Active</span>'
            if active else f'<span style="height: 40px; padding: 0 16px; border-radius: {R["button"]}px; background: {{{{c.accent}}}}; color: {{{{c.onAccent}}}}; display: inline-flex; align-items: center; font-family: {SANS}; {T["label"]}">Use</span>'
        )
        return card(
            f'<div style="display: flex; align-items: center; gap: 10px;"><div style="flex-grow: 1; min-width: 0; display: flex; align-items: center; gap: 8px;">{p(name, "subhead", "{{c.text}}")}{badge}</div>{action}</div>{gap(8)}'
            f'<div style="display: flex; gap: 8px; align-items: center;">{context_pill(branch, tappable=False)}{p("Phodex Cloud" if cloud else MAC_NAME, "caption", "{{c.muted}}")}</div>{gap(12)}'
            f'{terminal_block(path)}'
        )
    body = (
        header(None, bell=True) + gap(8)
        + hero("Repos", 34, align="left") + gap(16)
        + card(
            f'<div style="display: flex; align-items: center; gap: 12px;"><div style="width: 44px; height: 44px; border-radius: {R["chip"]}px; background: {{{{c.accentSoft}}}}; display: flex; align-items: center; justify-content: center;">{icon("cloud", 22, "{{c.accentDeep}}")}</div>'
            f'<div style="flex-grow: 1;">{p("Phodex Cloud", "titleM", "{{c.text}}")}{p("2 synced · 2 active", "caption")}</div>'
            f'<span style="padding: 4px 8px; border-radius: 999px; background: {{{{c.input}}}}; font-family: {SANS}; {T["captionM"]} color: {{{{c.text2}}}};">Metadata sync</span></div>{gap(12)}'
            f'{p("Cloud workspaces are cloned on Phodex Cloud and run there.", "caption")}{gap(8)}'
            f'<div style="display: flex; align-items: center; gap: 8px; color: {{{{c.accent}}}};">{icon("git", 18, "{{c.accent}}")}{p("Add GitHub repository", "label", "{{c.accent}}")}</div>'
        )
        + gap(24)
        + section_label("Repositories")
        + f'<div style="display: flex; flex-direction: column; gap: 16px;">{repo("phodex", "main", "…/GAURAV-1313__phodex", True, True)}{repo("demo-playground", "main", "…/demo__playground", False, True)}</div>'
    )
    return phone(body, with_dock="repos")


def repo_detail() -> str:
    body = (
        header("phodex", back=True, bell=False) + gap(8)
        + f'<div style="display: flex; gap: 8px; align-items: center;">{status_chip("completed", compact=True)}<span style="padding: 4px 8px; border-radius: 999px; background: {{{{c.accentSoft}}}}; font-family: {SANS}; {T["captionM"]} color: {{{{c.accentDeep}}}};">Cloud</span></div>'
        + gap(20)
        + card(
            f'{section_label("Workspace")}{terminal_block("/srv/phodex/workspaces/7f3a…/GAURAV-1313__phodex")}{gap(16)}'
            f'{section_label("Remote")}{p("github.com/GAURAV-1313/phodex", "bodySmall", "{{c.text}}")}{gap(16)}'
            f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">'
            f'<div>{p("BRANCH", "micro", "{{c.muted}}")}{p("main", "titleM", "{{c.text}}")}</div>'
            f'<div>{p("DEFAULT", "micro", "{{c.muted}}")}{p("main", "titleM", "{{c.text}}")}</div>'
            f'<div>{p("RUNNER", "micro", "{{c.muted}}")}{p("Phodex Cloud", "titleM", "{{c.text}}")}</div>'
            f'<div>{p("LAST SYNC", "micro", "{{c.muted}}")}{p("2 minutes ago", "titleM", "{{c.text}}")}</div></div>'
        )
        + gap(16)
        + banner("This is your active repository. New tasks run here.", "success")
        + spacer()
        + primary_button("Set as default", "check")
    )
    return phone(body)


def repo_not_found() -> str:
    body = (
        header("Repository", back=True, bell=False)
        + spacer()
        + empty_state("Repository not found", "It may have been removed or synced from another device.", "error", "Try again")
        + spacer()
    )
    return phone(body)


# --- Design system sheet ---------------------------------------------------
def design_system() -> str:
    def swatches(theme: str) -> str:
        pal = PALETTES[theme]
        names = list(pal.keys())
        cells = "".join(
            f'<div style="display: flex; flex-direction: column; gap: 6px; min-width: 0;"><div style="height: 48px; border-radius: 12px; background: {pal[n]}; border: 1px solid {pal["border"]};"></div>'
            f'<div style="font-family: {MONO}; font-size: 11px; line-height: 14px; color: {pal["text"]}; word-break: break-all;">{n}</div><div style="font-family: {MONO}; font-size: 10px; line-height: 13px; color: {pal["muted"]}; word-break: break-all;">{pal[n]}</div></div>'
            for n in names
        )
        return (
            f'<div style="background: {pal["bg"]}; border-radius: 24px; padding: 24px; border: 1px solid {pal["border"]};">'
            f'<div style="font-family: {SANS}; {T["micro"]} color: {pal["muted"]}; margin-bottom: 16px;">{theme} palette · {len(names)} tokens</div>'
            f'<div style="display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 12px;">{cells}</div></div>'
        )

    light = PALETTES["light"]
    ladder = [
        ("displayLarge · Fraunces 40/600", f"font-family: {SERIF}; font-size: 40px; line-height: 1.05; font-weight: 600; letter-spacing: -0.8px; color: {light['text']};", "Your AI engineer"),
        ("headlineMedium · Fraunces 28/600", f"font-family: {SERIF}; font-size: 28px; line-height: 34px; font-weight: 600; letter-spacing: -0.6px; color: {light['text']};", "Rotate refresh tokens"),
        ("headlineSmall · Plex Sans 24/600", f"font-family: {SANS}; {T['title']} color: {light['text']};", "Card headline"),
        ("titleLarge · 20/600", f"font-family: {SANS}; {T['subhead']} color: {light['text']};", "List title"),
        ("titleMedium · 17/600", f"font-family: {SANS}; {T['titleM']} color: {light['text']};", "Row title"),
        ("bodyLarge · 17/400", f"font-family: {SANS}; {T['body']} color: {light['text']};", "Default reading text for descriptions and prompts."),
        ("bodyMedium · 15/400 textSecondary", f"font-family: {SANS}; {T['bodySmall']} color: {light['text2']};", "Secondary body text."),
        ("bodySmall · 13/400 textSecondary", f"font-family: {SANS}; {T['caption']} color: {light['text2']};", "Captions, timestamps, meta."),
        ("labelLarge · 15/600", f"font-family: {SANS}; {T['label']} color: {light['text']};", "Button label"),
        ("labelSmall · 11/700 eyebrow textMuted", f"font-family: {SANS}; {T['micro']} color: {light['muted']};", "Section label"),
        ("code · Plex Mono 13", f"font-family: {MONO}; font-size: 13px; line-height: 18px; color: {light['text']};", "git push -u origin HEAD"),
    ]
    type_rows = "".join(
        f'<div style="display: grid; grid-template-columns: 260px minmax(0, 1fr); gap: 24px; align-items: baseline; padding: 12px 0; border-bottom: 1px solid {light["border"]};">'
        f'<div style="font-family: {MONO}; font-size: 12px; color: {light["muted"]};">{n}</div><div style="{st}">{sample}</div></div>'
        for n, st, sample in ladder
    )
    spacing = "".join(
        f'<div style="display: flex; flex-direction: column; align-items: center; gap: 8px;"><div style="width: {v}px; height: {v}px; background: {light["accent"]}; border-radius: 2px;"></div><div style="font-family: {MONO}; font-size: 12px; color: {light["muted"]};">s{v}</div></div>'
        for v in [2, 4, 8, 12, 16, 20, 24, 32, 40, 48]
    )
    radii = "".join(
        f'<div style="display: flex; flex-direction: column; align-items: center; gap: 8px;"><div style="width: {120 if n == "pill" else 88}px; height: {44 if n == "pill" else 88}px; background: {light["card"]}; border: 1px solid {light["border"]}; border-radius: {v}px; box-shadow: 0 5px 24px {light["shadow"]};"></div><div style="font-family: {MONO}; font-size: 12px; color: {light["muted"]};">{n} · {v}</div></div>'
        for n, v in R.items()
    )

    # Component samples are rendered with literal light tokens via the same helpers
    # by substituting the {{c.*}} holes.
    def lit(html: str, theme: str = "light") -> str:
        pal = PALETTES[theme]
        for k, v in pal.items():
            html = html.replace("{{c." + k + "}}", v)
        return html

    refresh_btn = (
        f'<div style="width: 48px; height: 48px; display: flex; align-items: center; '
        f'justify-content: center; color: {light["text"]};">{icon("refresh", 22)}</div>'
    )
    shell_sample = (
        f'<div style="position: relative; height: 220px; background: {light["bg"]}; border-radius: 24px; padding: 16px 24px; overflow: hidden;">'
        + lit(header("Approvals", back=True, trailing=refresh_btn))
        + '<div style="height: 12px;"></div>'
        + lit(card(p("A card on bgCard with the 24px radius and the theme shadow.", "bodySmall", "{{c.text2}}")))
        + lit(dock("repos"))
        + "</div>"
    )
    comps = [
        ("StitchPrimaryButton / StitchSecondaryButton", f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">{lit(primary_button("Continue with Google"))}{lit(secondary_button("Try the demo", "sparkle"))}</div>'),
        ("TaskStatusChip (default and compact)", f'<div style="display: flex; flex-direction: column; gap: 12px;"><div style="display: flex; gap: 12px; flex-wrap: wrap;">{lit(status_chip("queued"))}{lit(status_chip("running", pulse=True))}{lit(status_chip("waiting_approval"))}{lit(status_chip("completed"))}{lit(status_chip("failed"))}{lit(status_chip("cancelled"))}</div><div style="display: flex; gap: 12px; flex-wrap: wrap;">{lit(status_chip("running", compact=True, pulse=True))}{lit(status_chip("waiting_approval", compact=True))}{lit(status_chip("completed", compact=True))}</div></div>'),
        ("ContextPill", f'<div style="display: flex; gap: 12px; flex-wrap: wrap;">{lit(context_pill("phodex", "main"))}{lit(context_pill("Pick a repository", emphasized=True))}{lit(context_pill("feature/mobile-v1", tappable=False))}</div>'),
        ("StatusBanner", f'<div style="display: flex; flex-direction: column; gap: 12px;">{lit(banner("Reconnecting to live updates…", "warning", busy=True))}{lit(banner("Choose a repository before starting a task", "info", "Repos"))}{lit(banner("Changes committed and pushed", "success"))}{lit(banner(UNREACHABLE, "error", "Change runtime"))}</div>'),
        ("ComposerBar", f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">{lit(composer("Describe what you need built…", context_pill("phodex", "main")))}{lit(composer("Reply to this task…", running=True))}</div>'),
        ("StitchEmptyState / StitchErrorState", f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">{lit(empty_state("No tasks yet", "Describe what you need built and Phodex will get to work.", "curious", "Try an example"))}{lit(empty_state(ERR_TITLE, "Check your connection and try again.", "error", None, "Try again"))}</div>'),
        ("StitchTerminalBlock", lit(terminal_block("pytest -q tests/test_auth.py\n12 passed in 1.8s", "command · /workspace/phodex"))),
        ("StitchCard + StitchHeader + StitchDock", shell_sample),
    ]
    comp_html = "".join(
        f'<div style="display: flex; flex-direction: column; gap: 12px;"><div style="font-family: {MONO}; font-size: 12px; color: {light["muted"]};">{n}</div>{h}</div>'
        for n, h in comps
    )
    mascots = "".join(
        f'<div style="display: flex; flex-direction: column; align-items: center; gap: 8px;">{mascot(72, m)}<div style="font-family: {MONO}; font-size: 12px; color: {light["muted"]};">{m}</div></div>'
        for m in ["idle", "thinking", "curious", "success", "error", "resting"]
    )

    def section(title: str, body: str) -> str:
        return f'<div style="display: flex; flex-direction: column; gap: 16px;"><div style="font-family: {SERIF}; font-size: 28px; line-height: 34px; font-weight: 600; letter-spacing: -0.6px; color: {light["text"]};">{title}</div>{body}</div>'

    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  {FONT_LINK}
  <style>
    body {{ margin: 0; font-family: {SANS}; -webkit-font-smoothing: antialiased; }}
    a {{ color: #5B4FE8; }} a:hover {{ color: #433AC4; }}
    @keyframes pulse {{ from {{ opacity: 1; }} to {{ opacity: 0.4; }} }}
    @keyframes spin {{ to {{ transform: rotate(360deg); }} }}
  </style>
</helmet>
<div style="width: 1240px; min-height: 3400px; background: {light['bg']}; padding: 48px; display: flex; flex-direction: column; gap: 48px; box-sizing: border-box;">
  <div style="display: flex; align-items: center; gap: 20px;">{mascot(64)}<div><div style="font-family: {SERIF}; font-size: 40px; line-height: 1.05; font-weight: 600; letter-spacing: -0.8px; color: {light['text']};">Phodex design system</div><div style="font-family: {SANS}; {T['body']} color: {light['text2']};">Tokens and the shared kit, lifted from mobile/lib/shared. Warm cream, vivid indigo, Fraunces + IBM Plex.</div></div></div>
  {section("Color", f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 24px;">{swatches("light")}{swatches("dark")}</div>')}
  {section("Type ladder", f'<div style="display: flex; flex-direction: column;">{type_rows}</div>')}
  {section("Spacing", f'<div style="display: flex; gap: 32px; align-items: flex-end;">{spacing}</div>')}
  {section("Radii", f'<div style="display: flex; gap: 32px;">{radii}</div>')}
  {section("Mascot moods", f'<div style="display: flex; gap: 40px;">{mascots}</div>')}
  {section("Components", f'<div style="display: flex; flex-direction: column; gap: 32px;">{comp_html}</div>')}
</div>
</x-dc>
</body>
</html>
"""


ARTBOARDS = {
    "Welcome.dc.html": welcome,
    "Runtime.dc.html": runtime_choice,
    "ConnectDesktop.dc.html": connect_desktop,
    "SignIn.dc.html": sign_in,
    "FirstRepo.dc.html": first_repo,
    "Notifications.dc.html": notifications_step,
    "Main.dc.html": home_first_run,
    "Session.dc.html": session,
    "Approvals.dc.html": approvals,
    "Repos.dc.html": repos,
    "RepoDetail.dc.html": repo_detail,
    "RepoNotFound.dc.html": repo_not_found,
    "DesignSystem.dc.html": design_system,
}

PHONE_W, PHONE_H, GAP_X = 390, 844, 100


def main() -> None:
    for name, fn in ARTBOARDS.items():
        (OUT / name).write_text(fn())
    flow = ["Welcome", "Runtime", "ConnectDesktop", "SignIn", "FirstRepo", "Notifications", "Main"]
    screens = ["Session", "Approvals", "Repos", "RepoDetail", "RepoNotFound"]
    artboards = []
    for i, n in enumerate(flow):
        artboards.append({"file": f"{n}.dc.html", "x": i * (PHONE_W + GAP_X), "y": 0, "w": PHONE_W, "h": PHONE_H, "page": "flow",
                          "title": {"Main": "Home (first run)"}.get(n, None)})
    for i, n in enumerate(screens):
        artboards.append({"file": f"{n}.dc.html", "x": i * (PHONE_W + GAP_X), "y": 0, "w": PHONE_W, "h": PHONE_H, "page": "screens"})
    artboards.append({"file": "DesignSystem.dc.html", "x": 0, "y": 0, "w": 1240, "h": 3400, "page": "system", "expand": "fill"})
    for a in artboards:
        if a.get("title") is None:
            a.pop("title", None)
    canvas = {
        "pages": [
            {"id": "flow", "name": "Onboarding flow"},
            {"id": "screens", "name": "Screens"},
            {"id": "system", "name": "Design system"},
        ],
        "artboards": artboards,
        "annotations": [
            {"id": "flow-note", "x": 0, "y": -160, "w": 520, "page": "flow",
             "text": "Onboarding, left to right: Welcome → Runtime → Connect desktop (desktop path) → Sign in → First repo → Notifications → Home first run.\nEvery artboard has a Theme tweak (light/dark). Copy is literal; edit it in place."},
            {"id": "screens-note", "x": 0, "y": -140, "w": 520, "page": "screens",
             "text": "The three screens the audit flagged, rebuilt on the shell: Session (pinned composer with stop, trace cards, approval card), Approvals (summary + terminal payloads), Repos and Repo detail (overview card, cloud badge, not-found state)."},
            {"id": "system-note", "x": 1300, "y": 0, "w": 320, "page": "system",
             "text": "Tokens are lifted from app_colors.dart, app_typography.dart, app_spacing.dart and app_radii.dart. Components mirror stitch_ui.dart."},
        ],
        "launch": {"view": "canvas", "page": "flow"},
    }
    (OUT / "canvas.json").write_text(json.dumps(canvas, indent=2))
    print(f"wrote {len(ARTBOARDS)} artboards + canvas.json to {OUT}")


if __name__ == "__main__":
    main()
