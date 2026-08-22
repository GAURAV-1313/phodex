from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse

from app.api.deps import get_services
from app.services.pairing_service import generate_qr_data_uri, resolve_public_base_url
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/pair", tags=["pairing"])


# Deliberately unauthenticated: this is how a phone discovers the backend's
# address *before* it has ever signed in, the same local/tailnet trust
# boundary the rest of this local-first backend already relies on.
@router.get("", response_class=HTMLResponse)
async def pairing_page(
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> str:
    base_url, is_guessed = resolve_public_base_url(services.settings)
    qr_data_uri = generate_qr_data_uri(base_url)

    warning = ""
    if is_guessed:
        warning = """
        <p class="warning">
          This looks like your computer's local Wi-Fi address — it only works
          if your phone is on the <strong>same Wi-Fi network</strong>. To
          connect from anywhere (cellular data, a different network), set
          <code>PUBLIC_BASE_URL</code> in your backend's <code>.env</code>
          file — see the README for the easiest way (Tailscale).
        </p>
        """

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Connect Phodex</title>
<style>
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: #17151c;
    color: #f5f3f7;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    margin: 0;
    padding: 24px;
  }}
  main {{
    max-width: 420px;
    text-align: center;
  }}
  h1 {{
    font-size: 26px;
    margin-bottom: 8px;
  }}
  p.subtitle {{
    color: #a79fb0;
    margin-top: 0;
    margin-bottom: 28px;
  }}
  .qr-card {{
    background: #ffffff;
    border-radius: 24px;
    padding: 20px;
    display: inline-block;
  }}
  .qr-card img {{
    display: block;
    width: 260px;
    height: 260px;
  }}
  ol {{
    text-align: left;
    color: #d6d1de;
    margin-top: 28px;
    padding-left: 20px;
    line-height: 1.6;
  }}
  .url {{
    margin-top: 20px;
    font-family: ui-monospace, "SF Mono", Menlo, monospace;
    font-size: 14px;
    color: #8b7fff;
    background: #221f2a;
    border-radius: 12px;
    padding: 12px 16px;
    word-break: break-all;
    user-select: all;
  }}
  p.warning {{
    margin-top: 20px;
    font-size: 13px;
    color: #f3a73f;
    background: #2c2650;
    border-radius: 12px;
    padding: 12px 16px;
    text-align: left;
  }}
  code {{
    background: rgba(255,255,255,0.08);
    padding: 1px 5px;
    border-radius: 4px;
  }}
</style>
</head>
<body>
<main>
  <h1>Connect your phone</h1>
  <p class="subtitle">Scan this with the Phodex app to link this desktop.</p>
  <div class="qr-card">
    <img src="{qr_data_uri}" alt="QR code for {base_url}">
  </div>
  <div class="url">{base_url}</div>
  <ol>
    <li>Open the Phodex app on your phone.</li>
    <li>On the welcome screen, tap <strong>Connect to desktop</strong>.</li>
    <li>Scan this code.</li>
  </ol>
  {warning}
</main>
</body>
</html>
"""
