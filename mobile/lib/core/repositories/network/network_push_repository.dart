import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkPushRepository implements PushRepository {
  const NetworkPushRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<void> registerToken({
    required String fcmToken,
    required String platform,
  }) async {
    await _apiClient.postJson(
      '/push/register',
      body: {'fcm_token': fcmToken, 'platform': platform},
    );
  }

  @override
  Future<void> unregisterToken(String fcmToken) async {
    await _apiClient.postJson(
      '/push/unregister',
      body: {'fcm_token': fcmToken},
    );
  }
}
