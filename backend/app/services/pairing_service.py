import base64
import socket
from io import BytesIO

import qrcode

from app.core.config import Settings


def resolve_public_base_url(settings: Settings) -> tuple[str, bool]:
    """Returns (base_url, is_guessed).

    is_guessed is True when no PUBLIC_BASE_URL was configured and this is a
    best-effort local-network address — it only works for a phone on the
    same Wi-Fi, unlike a real Tailscale/tunnel address.
    """
    if settings.public_base_url:
        return settings.public_base_url.rstrip("/"), False
    return f"http://{_guess_local_ip()}:8000", True


def _guess_local_ip() -> str:
    # Opens a UDP "connection" to a public address without sending any
    # packets, purely so the OS picks the outbound-facing local interface —
    # a standard, dependency-free trick for finding "this machine's LAN IP."
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))
        return str(sock.getsockname()[0])
    except OSError:
        return "127.0.0.1"
    finally:
        sock.close()


def generate_qr_data_uri(data: str) -> str:
    image = qrcode.make(data)
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    encoded = base64.b64encode(buffer.getvalue()).decode("ascii")
    return f"data:image/png;base64,{encoded}"
