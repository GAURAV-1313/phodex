import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/notifications/application/push_notification_controller.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';

/// Wakes the push controller as soon as there is a signed-in user on a
/// Firebase-enabled build, so a permission the user granted on a previous
/// launch re-registers this device's token without them ever opening the
/// Notifications screen. Purely a side-effect hook: it renders [child]
/// unchanged, never throws, and does nothing in mock mode.
class PushBootstrapper extends ConsumerWidget {
  const PushBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(
      authControllerProvider.select((auth) => auth.value == true),
    );
    final firebaseAvailable = ref.watch(firebaseAvailableProvider);
    final useNetwork = ref.watch(
      apiConfigProvider.select((config) => config.useNetwork),
    );

    if (signedIn && firebaseAvailable && useNetwork) {
      // Listening (rather than watching) initializes the controller without
      // rebuilding the whole app every time the permission status changes.
      ref.listen(pushNotificationControllerProvider, (_, _) {});
    }
    return child;
  }
}
