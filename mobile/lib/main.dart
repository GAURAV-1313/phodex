import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/push/push_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read any previously-paired desktop address before the widget tree
  // builds, so the very first network call already targets the right
  // backend instead of racing an async restore.
  final prefs = await SharedPreferences.getInstance();
  final pairedServerUrl = prefs.getString(serverUrlPrefsKey);

  // Best-effort: fails (and is caught) with the placeholder firebase_options
  // until `flutterfire configure` has been run against a real project — push
  // notifications just stay unavailable, nothing else in the app depends on
  // this succeeding.
  final firebaseAvailable = await initializeFirebase();

  runApp(
    ProviderScope(
      overrides: [
        if (pairedServerUrl != null && pairedServerUrl.isNotEmpty)
          persistedServerUrlOverrideProvider.overrideWithValue(pairedServerUrl),
        firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
      ],
      child: const PhodexApp(),
    ),
  );
}
