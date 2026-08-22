import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';

final sessionsProvider =
    AsyncNotifierProvider<SessionsController, List<SessionInfo>>(
      SessionsController.new,
    );

class SessionsController extends AsyncNotifier<List<SessionInfo>> {
  @override
  Future<List<SessionInfo>> build() async {
    return ref.watch(accountRepositoryProvider).listSessions();
  }

  Future<void> revoke(String sessionId) async {
    await ref.read(accountRepositoryProvider).revokeSession(sessionId);
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).listSessions(),
    );
  }

  Future<int> revokeOthers() async {
    final revokedCount = await ref
        .read(accountRepositoryProvider)
        .revokeOtherSessions();
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).listSessions(),
    );
    return revokedCount;
  }
}
