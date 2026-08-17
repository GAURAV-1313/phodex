import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';

final aiSettingsStatusProvider =
    AsyncNotifierProvider<AiSettingsController, AiSettingsStatus>(
      AiSettingsController.new,
    );

class AiSettingsController extends AsyncNotifier<AiSettingsStatus> {
  @override
  Future<AiSettingsStatus> build() async {
    return ref.watch(aiSettingsRepositoryProvider).getStatus();
  }

  Future<void> saveSettings({
    String? anthropicApiKey,
    String? openaiApiKey,
    bool clearAnthropicKey = false,
    bool clearOpenaiKey = false,
    String? preferredClaudeModel,
    String? preferredCodexModel,
  }) async {
    final repository = ref.read(aiSettingsRepositoryProvider);
    final updated = await repository.update(
      anthropicApiKey: anthropicApiKey,
      openaiApiKey: openaiApiKey,
      clearAnthropicKey: clearAnthropicKey,
      clearOpenaiKey: clearOpenaiKey,
      preferredClaudeModel: preferredClaudeModel,
      preferredCodexModel: preferredCodexModel,
    );
    state = AsyncData(updated);
  }
}
