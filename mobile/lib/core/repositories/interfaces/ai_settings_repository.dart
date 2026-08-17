import 'package:mobile/core/domain/models/models.dart';

abstract class AiSettingsRepository {
  Future<AiSettingsStatus> getStatus();

  Future<AiSettingsStatus> update({
    String? anthropicApiKey,
    String? openaiApiKey,
    bool clearAnthropicKey = false,
    bool clearOpenaiKey = false,
    String? preferredClaudeModel,
    String? preferredCodexModel,
  });
}
