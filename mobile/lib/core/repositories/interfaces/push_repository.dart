abstract class PushRepository {
  Future<void> registerToken({
    required String fcmToken,
    required String platform,
  });

  Future<void> unregisterToken(String fcmToken);
}
