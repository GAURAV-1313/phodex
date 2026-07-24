import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/shared/theme/theme.dart';

Widget wrapWithTestApp(Widget child, {MockBackendStore? store}) {
  final effectiveStore =
      store ?? MockBackendStore(enableDynamicSimulation: false);
  return ProviderScope(
    overrides: [
      apiConfigProvider.overrideWithValue(
        const ApiConfig(
          useNetwork: false,
          baseUrl: 'http://test',
          googleIdToken: 'test',
        ),
      ),
      mockBackendStoreProvider.overrideWithValue(effectiveStore),
    ],
    child: MaterialApp(theme: AppTheme.dark(), home: child),
  );
}
