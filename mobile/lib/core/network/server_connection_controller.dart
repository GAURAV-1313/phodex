import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared with `main.dart`, which reads this key once at startup (before
/// [ProviderScope] exists) so the very first [ApiConfig] built already has
/// the right address — avoiding a race between that and this controller's
/// own async restore.
const serverUrlPrefsKey = 'phodex_server_url';

final serverUrlProvider = NotifierProvider<ServerUrlController, String?>(
  ServerUrlController.new,
);

/// Tracks the desktop backend address the user paired with via the
/// "Connect to desktop" flow (QR scan or manual entry), persisting it so
/// pairing survives app restarts, and reflects it live if it changes while
/// the app is already running (e.g. re-pairing with a different desktop).
///
/// `state` is null until pairing has genuinely happened at least once —
/// including briefly on a real restore, matching this app's "restore,
/// don't block" pattern (see `ThemeModeController`, `AuthController`).
class ServerUrlController extends Notifier<String?> {
  @override
  String? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(serverUrlPrefsKey);
    if (stored != null && stored.isNotEmpty) {
      state = stored;
    }
  }

  bool get isConfigured => state != null && state!.isNotEmpty;

  Future<void> setServerUrl(String url) async {
    final normalized = url.trim();
    state = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverUrlPrefsKey, normalized);
    ref.read(apiClientProvider).updateBaseUrl(normalized);
  }

  Future<void> forget() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(serverUrlPrefsKey);
  }
}
