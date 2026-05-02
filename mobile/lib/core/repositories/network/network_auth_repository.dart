import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkAuthRepository implements AuthRepository {
  const NetworkAuthRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<UserProfile> getMe() async {
    final json = await _apiClient.getJson('/auth/me');
    return UserOutDto.fromJson(json).toDomain();
  }
}
