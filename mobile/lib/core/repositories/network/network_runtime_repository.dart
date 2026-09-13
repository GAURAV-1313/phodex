import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class NetworkRuntimeRepository implements RuntimeRepository {
  const NetworkRuntimeRepository(this._apiClient);

  final PhodexApiClient _apiClient;

  @override
  Future<RuntimeInfo> getRuntimeInfo() async {
    final json = await _apiClient.getJson('/runtime');
    return RuntimeInfoDto.fromJson(json).toDomain();
  }
}
