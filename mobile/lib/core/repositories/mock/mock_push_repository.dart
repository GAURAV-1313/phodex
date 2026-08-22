import 'package:mobile/core/repositories/interfaces/interfaces.dart';

class MockPushRepository implements PushRepository {
  const MockPushRepository();

  @override
  Future<void> registerToken({
    required String fcmToken,
    required String platform,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  @override
  Future<void> unregisterToken(String fcmToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
}
