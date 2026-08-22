import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/welcome/application/connect_desktop_controller.dart';
import 'package:mobile/features/welcome/presentation/qr_scan_screen.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// Lets the user point the mobile app at their own desktop backend — by
/// scanning the QR code shown at its /pair page, or typing the address by
/// hand. No account is needed yet; this has to work before sign-in can.
class ConnectDesktopScreen extends ConsumerStatefulWidget {
  const ConnectDesktopScreen({super.key});

  @override
  ConsumerState<ConnectDesktopScreen> createState() =>
      _ConnectDesktopScreenState();
}

class _ConnectDesktopScreenState extends ConsumerState<ConnectDesktopScreen> {
  final _urlController = TextEditingController();
  bool _showManualEntry = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final scanned = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
    if (scanned == null || !mounted) return;
    _urlController.text = scanned;
    await ref
        .read(connectDesktopControllerProvider.notifier)
        .testAndConnect(scanned);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectDesktopControllerProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StitchHeader(
                title: 'Connect to desktop',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 28),
              Text(
                'On your laptop, run the Phodex backend and open its /pair '
                'page — scan the code it shows, or type the address below.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              if (state.status == ConnectionTestStatus.success)
                _SuccessCard(url: state.url)
              else ...[
                StitchPrimaryButton(
                  label: 'Scan QR code',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: state.status == ConnectionTestStatus.testing
                      ? null
                      : _scanQrCode,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _showManualEntry = !_showManualEntry),
                    child: Text(
                      _showManualEntry
                          ? 'Hide manual entry'
                          : 'Enter the address manually instead',
                    ),
                  ),
                ),
                if (_showManualEntry) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'http://100.x.x.x:8000',
                      labelText: 'Desktop address',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.status == ConnectionTestStatus.testing
                          ? null
                          : () => ref
                                .read(connectDesktopControllerProvider.notifier)
                                .testAndConnect(_urlController.text),
                      child: Text(
                        state.status == ConnectionTestStatus.testing
                            ? 'Checking…'
                            : 'Connect',
                      ),
                    ),
                  ),
                ],
                if (state.status == ConnectionTestStatus.failure) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.accentError.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      state.errorMessage ?? 'Could not connect.',
                      style: TextStyle(color: context.colors.accentError),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return StitchCard(
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: context.colors.accentSuccess,
          ),
          const SizedBox(height: 14),
          const Text(
            'Connected!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(url, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 20),
          StitchPrimaryButton(
            label: 'Continue',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
