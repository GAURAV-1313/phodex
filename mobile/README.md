# Phodex mobile

Phodex is a Flutter companion for the host-run Codex worker. It creates tasks,
streams execution over SSE, and handles approval decisions through the local
FastAPI backend.

## Local demo: Android emulator

Start Postgres/Redis infrastructure and the host backend first, then run:

```bash
flutter pub get
flutter run \
  --dart-define=PHODEX_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=PHODEX_GOOGLE_ID_TOKEN='test-token|local-user|gaurav@example.com|Gaurav Local'
```

The backend `.env` must set `ALLOW_INSECURE_TEST_TOKENS=true`. This development
token is accepted only by the local backend; it is intentionally not the app
default and must never be used in a production build.

For an iOS simulator, replace the base URL with `http://127.0.0.1:8000`.
For a physical device, use the Mac's LAN address and add that origin to the
backend `ALLOWED_ORIGINS` setting.

## Real Google sign-in

The Welcome screen now exchanges an ID token from native Google Sign-In for a
Phodex JWT. Create Android and iOS OAuth clients for bundle/application ID
`com.phodex.mobile`, configure their signing credentials, and pass the client
IDs only at build time:

```bash
flutter run \
  --dart-define=PHODEX_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=PHODEX_GOOGLE_SERVER_CLIENT_ID='<web-oauth-client-id>' \
  --dart-define=PHODEX_GOOGLE_IOS_CLIENT_ID='<ios-oauth-client-id>'
```

Set the same web OAuth client ID as `GOOGLE_CLIENT_ID` in `backend/.env`. On
iOS, also add the reversed iOS client ID URL scheme required by the Google
Sign-In SDK — `ios/Runner/Info.plist` already has a marked placeholder for
this, just paste your value in. Android can use `google-services.json`
instead of a supplied server client ID. These platform registration steps are
required by the Google SDK, not by Phodex — see the backend README's
"Setting up real Google Sign-In" section for the full step-by-step walkthrough
(creating the OAuth clients, the consent screen, the Android SHA-1
fingerprint).

## Push notifications

The Account → Notifications screen and the backend's push-sending code are
both real and already wired (approval needed, task completed/failed). What's
missing is your own Firebase project — until `flutterfire configure` has
been run, `Firebase.initializeApp()` fails safely at startup and the
Notifications screen shows an honest "not set up on this build yet" instead
of a working toggle; nothing else in the app is affected. See the backend
README's "Setting up real push notifications" section for the full
walkthrough (Firebase project, service-account key, `flutterfire configure`,
and the one manual Xcode step for iOS's Push Notifications capability).

## Connecting to a real desktop (no rebuild needed)

`--dart-define=PHODEX_BASE_URL=...` above is only a *build-time default* —
useful for local dev, but not something an installed app can be pointed at a
different backend with after the fact. For real use, the Welcome screen has
a **Connect to your desktop** link: scan the QR code shown at the backend's
`/pair` page (or type the address by hand), and the app remembers it from
then on, overriding the compile-time default. See the backend README's
"Connecting your phone remotely" section for the full setup, including
Tailscale for access from outside your home Wi-Fi. The address can be
changed later from Account → Desktop connection.

## UI-only mode

```bash
flutter run --dart-define=PHODEX_USE_NETWORK=false
```

## Verification

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```
