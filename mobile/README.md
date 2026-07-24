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
Sign-In SDK to `ios/Runner/Info.plist`. Android can use `google-services.json`
instead of a supplied server client ID. These platform registration steps are
required by the Google SDK, not by Phodex.

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
