import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/welcome/application/connect_desktop_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A dedicated, non-widget test file: `testWidgets` (used elsewhere in this
// suite) initializes TestWidgetsFlutterBinding, which blocks all real HTTP
// for the entire file it appears in — even plain `test()` calls in that same
// file. Keeping this file free of `testWidgets` is what lets these tests
// make real requests to a real local HttpServer, same reasoning as
// network_repository_test.dart.
void main() {
  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [
      apiConfigProvider.overrideWithValue(
        const ApiConfig(
          useNetwork: false,
          baseUrl: 'http://test',
          googleIdToken: 'test',
        ),
      ),
    ],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('succeeds against a reachable address and persists it', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"status": "ok"}')
        ..close();
    });
    addTearDown(server.close);
    final url = 'http://${server.address.address}:${server.port}';

    final container = buildContainer();
    addTearDown(container.dispose);

    await container
        .read(connectDesktopControllerProvider.notifier)
        .testAndConnect(url);

    final state = container.read(connectDesktopControllerProvider);
    expect(state.status, ConnectionTestStatus.success);
    expect(container.read(serverUrlProvider), url);
  });

  test('fails against an unreachable address with a clear message', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    // Port 1 on loopback: nothing listens there, so this fails fast with
    // connection-refused instead of waiting out a real timeout.
    await container
        .read(connectDesktopControllerProvider.notifier)
        .testAndConnect('http://127.0.0.1:1');

    final state = container.read(connectDesktopControllerProvider);
    expect(state.status, ConnectionTestStatus.failure);
    expect(state.errorMessage, contains("Couldn't reach that address"));
    expect(container.read(serverUrlProvider), isNull);
  });

  test('rejects empty input without attempting a connection', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await container
        .read(connectDesktopControllerProvider.notifier)
        .testAndConnect('   ');

    final state = container.read(connectDesktopControllerProvider);
    expect(state.status, ConnectionTestStatus.failure);
    expect(state.errorMessage, contains('Enter a valid address'));
  });
}
