import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkAiSettingsRepository implements AiSettingsRepository {
  const NetworkAiSettingsRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<AiSettingsStatus> getStatus() async {
    final json = await _apiClient.getJson('/account/ai-settings');
    return AiSettingsStatusResponseDto.fromJson(json).toDomain();
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
    final json = await _apiClient.putJson(
      '/account/ai-settings',
      body: {
        'anthropic_api_key': anthropicApiKey,
        'openai_api_key': openaiApiKey,
        'clear_anthropic_key': clearAnthropicKey,
        'clear_openai_key': clearOpenaiKey,
        'preferred_claude_model': preferredClaudeModel,
        'preferred_codex_model': preferredCodexModel,
      },
    );
    return AiSettingsStatusResponseDto.fromJson(json).toDomain();
  }
}
