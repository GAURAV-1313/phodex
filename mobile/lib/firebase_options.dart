// PLACEHOLDER — replace by running `flutterfire configure` from mobile/,
// signed in to your own Firebase project. That command overwrites this
// entire file with real, working values (and drops the matching
// google-services.json / GoogleService-Info.plist alongside it), so there
// is nothing to hand-edit here.
//
// Until that's done, Firebase.initializeApp() in main.dart will fail with
// these placeholder values — by design, that failure is caught there and
// push notifications simply stay disabled; the rest of the app is
// unaffected either way.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String placeholderMarker = 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — run '
        'flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: placeholderMarker,
    appId: placeholderMarker,
    messagingSenderId: placeholderMarker,
    projectId: placeholderMarker,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: placeholderMarker,
    appId: placeholderMarker,
    messagingSenderId: placeholderMarker,
    projectId: placeholderMarker,
    iosBundleId: 'com.phodex.mobile',
  );
}
