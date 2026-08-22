import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/server_connection_controller.dart';

enum ConnectionTestStatus { idle, testing, success, failure }

class ConnectDesktopState {
  const ConnectDesktopState({
    this.status = ConnectionTestStatus.idle,
    this.url = '',
    this.errorMessage,
  });

  final ConnectionTestStatus status;
  final String url;
  final String? errorMessage;

  ConnectDesktopState copyWith({
    ConnectionTestStatus? status,
    String? url,
    String? errorMessage,
  }) {
    return ConnectDesktopState(
      status: status ?? this.status,
      url: url ?? this.url,
      errorMessage: errorMessage,
    );
  }
}

final connectDesktopControllerProvider =
    NotifierProvider<ConnectDesktopController, ConnectDesktopState>(
      ConnectDesktopController.new,
    );

/// Drives the "Connect to desktop" flow: validate a scanned/typed address,
/// confirm the backend is actually reachable, then persist it. Kept separate
/// from the presentation layer so it's testable without a real camera.
class ConnectDesktopController extends Notifier<ConnectDesktopState> {
  @override
  ConnectDesktopState build() => const ConnectDesktopState();

  Future<void> testAndConnect(String rawInput) async {
    final url = _normalize(rawInput);
    if (url == null) {
      state = ConnectDesktopState(
        status: ConnectionTestStatus.failure,
        url: rawInput,
        errorMessage: 'Enter a valid address, like http://100.x.x.x:8000',
      );
      return;
    }

    state = ConnectDesktopState(status: ConnectionTestStatus.testing, url: url);

    final reachable = await PhodexApiClient.testConnection(url);
    if (!reachable) {
      state = ConnectDesktopState(
        status: ConnectionTestStatus.failure,
        url: url,
        errorMessage:
            "Couldn't reach that address. Make sure your desktop is running "
            'Phodex and the address is correct.',
      );
      return;
    }

    await ref.read(serverUrlProvider.notifier).setServerUrl(url);
    state = ConnectDesktopState(status: ConnectionTestStatus.success, url: url);
  }

  void reset() => state = const ConnectDesktopState();

  static String? _normalize(String rawInput) {
    var input = rawInput.trim();
    if (input.isEmpty) return null;
    if (!input.contains('://')) {
      input = 'http://$input';
    }
    final uri = Uri.tryParse(input);
    if (uri == null || uri.host.isEmpty || !uri.hasScheme) return null;
    return uri.toString();
  }
}
