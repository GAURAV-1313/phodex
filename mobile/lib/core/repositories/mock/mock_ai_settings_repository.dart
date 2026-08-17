import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockAiSettingsRepository implements AiSettingsRepository {
  const MockAiSettingsRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<AiSettingsStatus> getStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.getAiSettingsStatus();
  }

  @override
  Future<AiSettingsStatus> update({
    String? anthropicApiKey,
    String? openaiApiKey,
    bool clearAnthropicKey = false,
    bool clearOpenaiKey = false,
    String? preferredClaudeModel,
    String? preferredCodexModel,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _store.updateAiSettings(
      anthropicApiKey: anthropicApiKey,
      openaiApiKey: openaiApiKey,
      clearAnthropicKey: clearAnthropicKey,
      clearOpenaiKey: clearOpenaiKey,
      preferredClaudeModel: preferredClaudeModel,
      preferredCodexModel: preferredCodexModel,
    );
  }
}
