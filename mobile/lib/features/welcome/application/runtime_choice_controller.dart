import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/core/providers/repository_providers.dart';

/// The user's answer to "Where should tasks run?" plus what the chosen
/// backend said about itself — kept in memory for the rest of the sign-in
/// flow (the sign-in screen needs to know whether a demo account exists).
class RuntimeChoiceState {
  const RuntimeChoiceState({
    this.mode,
    this.demoAvailable = false,
    this.runnerName,
    this.busy = false,
    this.errorMessage,
  });

  /// Null until the user has picked; the sign-in screen then falls back to
  /// comparing the configured server address against the cloud address.
  final RuntimeMode? mode;
  final bool demoAvailable;
  final String? runnerName;
  final bool busy;
  final String? errorMessage;

  RuntimeChoiceState copyWith({
    RuntimeMode? mode,
    bool? demoAvailable,
    String? runnerName,
    bool? busy,
    String? errorMessage,
  }) => RuntimeChoiceState(
    mode: mode ?? this.mode,
    demoAvailable: demoAvailable ?? this.demoAvailable,
    runnerName: runnerName ?? this.runnerName,
    busy: busy ?? this.busy,
    errorMessage: errorMessage,
  );
}

final runtimeChoiceProvider =
    NotifierProvider<RuntimeChoiceController, RuntimeChoiceState>(
      RuntimeChoiceController.new,
    );

class RuntimeChoiceController extends Notifier<RuntimeChoiceState> {
  @override
  RuntimeChoiceState build() => const RuntimeChoiceState();

  /// Points the app at Phodex Cloud. Probes the hosted backend first (in
  /// real network mode) so an outage surfaces here, on the choice screen,
  /// rather than as a mysterious sign-in failure two screens later.
  /// Returns whether the choice took effect.
  Future<bool> chooseCloud() async {
    final config = ref.read(apiConfigProvider);
    final cloudUrl = config.cloudBaseUrl;
    state = state.copyWith(busy: true);

    var demoAvailable = false;
    String? runnerName;
    if (config.useNetwork) {
      final probe = await PhodexApiClient.probeRuntime(cloudUrl);
      if (probe == null) {
        state = state.copyWith(
          busy: false,
          errorMessage: 'Phodex Cloud is unreachable right now',
        );
        return false;
      }
      demoAvailable = probe['demo_available'] == true;
      runnerName = probe['runner_name'] as String?;
    } else {
      // UI-only mode: the mock backend becomes the cloud runtime the user
      // just chose, so the rest of the flow (demo sign-in, GitHub repo form,
      // cloud copy on Repos) reflects that choice.
      ref.read(mockBackendStoreProvider).switchRuntime(RuntimeMode.cloud);
      demoAvailable = true;
    }

    await ref.read(serverUrlProvider.notifier).setServerUrl(cloudUrl);
    state = RuntimeChoiceState(
      mode: RuntimeMode.cloud,
      demoAvailable: demoAvailable,
      runnerName: runnerName ?? 'Phodex Cloud',
    );
    return true;
  }

  /// The user wants to pair their own laptop; the address itself is
  /// collected by the Connect-desktop flow.
  void chooseDesktop() {
    if (!ref.read(apiConfigProvider).useNetwork) {
      ref.read(mockBackendStoreProvider).switchRuntime(RuntimeMode.desktop);
    }
    state = const RuntimeChoiceState(mode: RuntimeMode.desktop);
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
