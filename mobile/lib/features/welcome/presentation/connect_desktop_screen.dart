import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/features/welcome/application/connect_desktop_controller.dart';
import 'package:mobile/features/welcome/presentation/onboarding_nav.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// Lets the user point the mobile app at their own desktop backend — by
/// scanning the QR code shown at its /pair page, or typing the address by
/// hand. No account is needed yet; this has to work before sign-in can.
///
/// During onboarding "Continue" moves on to sign-in. With `?from=account`
/// or `?from=setup` the screen is a detour, and "Continue" pops back with
/// `true` so the caller knows pairing succeeded.
class ConnectDesktopScreen extends ConsumerStatefulWidget {
  const ConnectDesktopScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<ConnectDesktopScreen> createState() =>
      _ConnectDesktopScreenState();
}

class _ConnectDesktopScreenState extends ConsumerState<ConnectDesktopScreen> {
  final _urlController = TextEditingController();
  late final ConnectDesktopController _controller;
  bool _showManualEntry = false;

  bool get _isDetour => widget.from != null;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(connectDesktopControllerProvider.notifier);
    // A previous visit's result (typically "Connected!") must not greet the
    // user on the next one — every entry starts from the idle state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.reset());
  }

  @override
  void dispose() {
    _urlController.dispose();
    // `ref` is unusable once the element is unmounted, hence the notifier
    // cached in initState; deferred so it never mutates providers mid-build.
    final controller = _controller;
    scheduleMicrotask(() {
      try {
        controller.reset();
      } catch (_) {
        // The container may already be gone (app teardown) — nothing to do.
      }
    });
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final scanned = await context.push<String>('/scan');
    if (scanned == null || !mounted) return;
    _urlController.text = scanned;
    await _controller.testAndConnect(scanned);
  }

  void _continue() {
    if (_isDetour) {
      context.pop(true);
    } else {
      context.push('/sign-in');
    }
  }

  Future<void> _forget() async {
    await ref.read(serverUrlProvider.notifier).forget();
    _controller.reset();
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectDesktopControllerProvider);
    final pairedUrl = ref.watch(serverUrlProvider);
    final testing = state.status == ConnectionTestStatus.testing;
    final succeeded = state.status == ConnectionTestStatus.success;

    return StitchScaffold(
      key: const Key('connect-desktop-screen'),
      showDock: false,
      child: ListView(
        padding: stitchScreenPaddingNoDock,
        children: [
          StitchHeader(
            title: 'Connect desktop',
            onBack: () => popOrGo(context, '/runtime'),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'On your laptop, run the Phodex backend and open its /pair '
            'page — scan the code it shows, or type the address below.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s24),
          if (succeeded)
            _SuccessCard(
              url: state.url,
              onContinue: _continue,
              onForget: _forget,
            )
          else ...[
            if (pairedUrl != null && pairedUrl.isNotEmpty) ...[
              _PairedCard(url: pairedUrl, onForget: _forget),
              const SizedBox(height: AppSpacing.s16),
            ],
            StitchPrimaryButton(
              key: const Key('connect-desktop-scan'),
              label: 'Scan QR code',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: testing ? null : _scanQrCode,
            ),
            const SizedBox(height: AppSpacing.s12),
            StitchSecondaryButton(
              key: const Key('connect-desktop-manual-toggle'),
              label: _showManualEntry
                  ? 'Hide manual entry'
                  : 'Enter the address manually instead',
              icon: _showManualEntry
                  ? Icons.keyboard_hide_outlined
                  : Icons.keyboard_outlined,
              onPressed: () =>
                  setState(() => _showManualEntry = !_showManualEntry),
            ),
            if (_showManualEntry) ...[
              const SizedBox(height: AppSpacing.s16),
              TextField(
                key: const Key('connect-desktop-url-field'),
                controller: _urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                onSubmitted: testing
                    ? null
                    : (value) => _controller.testAndConnect(value),
                decoration: const InputDecoration(
                  hintText: 'http://100.x.x.x:8000',
                  labelText: 'Desktop address',
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              StitchPrimaryButton(
                key: const Key('connect-desktop-connect'),
                label: testing ? 'Checking…' : 'Connect',
                loading: testing,
                onPressed: () =>
                    _controller.testAndConnect(_urlController.text),
              ),
            ],
            if (state.status == ConnectionTestStatus.failure) ...[
              const SizedBox(height: AppSpacing.s16),
              StatusBanner(
                message: state.errorMessage ?? 'Could not connect.',
                tone: StatusTone.error,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.url,
    required this.onContinue,
    required this.onForget,
  });

  final String url;
  final VoidCallback onContinue;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StitchCard(
      child: Column(
        children: [
          const PhodexMascot(size: 72, mood: MascotMood.success),
          const SizedBox(height: AppSpacing.s16),
          Text('Connected!', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.s4),
          Text(
            url,
            textAlign: TextAlign.center,
            style: AppTypography.code(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s20),
          StitchPrimaryButton(
            key: const Key('connect-desktop-continue'),
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.s4),
          TextButton(
            onPressed: onForget,
            child: const Text('Forget this desktop'),
          ),
        ],
      ),
    );
  }
}

/// Shown when a desktop is already paired (revisiting from Account): what
/// the app is currently pointed at, and a way to unpair.
class _PairedCard extends StatelessWidget {
  const _PairedCard({required this.url, required this.onForget});

  final String url;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StitchCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
      ),
      child: Row(
        children: [
          Icon(Icons.desktop_windows_outlined, color: colors.accentSuccess),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Currently paired', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  url,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.code(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('connect-desktop-forget'),
            onPressed: onForget,
            child: const Text('Forget'),
          ),
        ],
      ),
    );
  }
}
