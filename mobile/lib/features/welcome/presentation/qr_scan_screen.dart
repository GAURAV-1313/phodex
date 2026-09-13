import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/welcome/application/phodex_address.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A thin camera screen — pops with a validated backend address once a
/// Phodex QR code is detected, or with null if the user backs out or asks
/// to type the address instead. Kept separate from ConnectDesktopScreen so
/// the rest of that flow stays testable without a real camera.
///
/// The camera preview is the one surface in the app that is always dark,
/// so the whole screen renders under the dark theme regardless of the
/// user's setting — every token drawn over the camera then reads correctly
/// without any per-widget color overrides.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController();
  late final ThemeData _cameraTheme = AppTheme.dark();
  bool _handled = false;
  String? _lastRejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    final address = parsePhodexAddress(value);
    if (address == null) {
      // Keep scanning; just say why this code didn't work. Only react once
      // per distinct payload so a code held in frame doesn't re-trigger.
      if (_lastRejected != value) setState(() => _lastRejected = value);
      return;
    }
    _handled = true;
    context.pop(address);
  }

  void _enterManually() => context.pop();

  @override
  Widget build(BuildContext context) => Theme(
    data: _cameraTheme,
    child: Builder(builder: _buildScanner),
  );

  Widget _buildScanner(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      key: const Key('qr-scan-screen'),
      backgroundColor: colors.bgPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) =>
                _ScannerUnavailable(error: error, onManual: _enterManually),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Close scanner',
                        child: Material(
                          color: colors.bgPrimary.withValues(alpha: .6),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            key: const Key('qr-scan-close'),
                            tooltip: 'Close scanner',
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s24,
                    AppSpacing.s24,
                    AppSpacing.s24,
                    AppSpacing.s16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgPrimary.withValues(alpha: .82),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.sheet),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_lastRejected != null) ...[
                        const StatusBanner(
                          message: "That QR code isn't a Phodex address",
                          tone: StatusTone.error,
                        ),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                      Text(
                        'Point your camera at the QR code on your '
                        "desktop's /pair page",
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Semantics(
                        button: true,
                        label: 'Enter address manually instead of scanning',
                        child: TextButton(
                          key: const Key('qr-scan-manual'),
                          onPressed: _enterManually,
                          child: const Text('Enter address manually'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the user sees instead of a camera preview when the scanner can't
/// start — most often because camera permission was declined. Always
/// offers the manual path so a missing camera never blocks pairing.
class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable({required this.error, required this.onManual});

  final MobileScannerException error;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: context.colors.bgPrimary,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PhodexMascot(size: 72, mood: MascotMood.error),
                const SizedBox(height: AppSpacing.s20),
                Text(
                  denied ? 'Camera access is off' : "Couldn't start the camera",
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  denied
                      ? 'Allow camera access for Phodex in your phone\'s '
                            'Settings, or type the address instead.'
                      : 'You can type the address from your desktop\'s '
                            '/pair page instead.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.s24),
                Semantics(
                  button: true,
                  label: 'Enter address manually instead of scanning',
                  child: StitchSecondaryButton(
                    label: 'Enter address manually',
                    icon: Icons.keyboard_outlined,
                    onPressed: onManual,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
