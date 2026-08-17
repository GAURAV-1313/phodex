import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/ai_engine/application/ai_settings_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class AiEngineScreen extends ConsumerWidget {
  const AiEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(aiSettingsStatusProvider);
    return StitchScaffold(
      active: StitchTab.account,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
        children: [
          StitchHeader(title: 'AI engine', onBack: () => context.pop()),
          const SizedBox(height: 28),
          const Text(
            'Phodex uses whatever Codex or Claude CLI is already logged in '
            'on your desktop by default. Setting a key below overrides that '
            'for your own tasks only — leave it blank to keep using the '
            'desktop login.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          value.when(
            data: (status) => _AiEngineForm(status: status),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 60),
              child: PhodexLoading(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: 60),
              child: StitchErrorState(
                title: "Couldn't load AI engine settings",
                onRetry: () => ref.invalidate(aiSettingsStatusProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiEngineForm extends ConsumerStatefulWidget {
  const _AiEngineForm({required this.status});
  final AiSettingsStatus status;

  @override
  ConsumerState<_AiEngineForm> createState() => _AiEngineFormState();
}

class _AiEngineFormState extends ConsumerState<_AiEngineForm> {
  late final _anthropicKey = TextEditingController();
  late final _openaiKey = TextEditingController();
  late final _claudeModel = TextEditingController(
    text: widget.status.preferredClaudeModel ?? '',
  );
  late final _codexModel = TextEditingController(
    text: widget.status.preferredCodexModel ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _anthropicKey.dispose();
    _openaiKey.dispose();
    _claudeModel.dispose();
    _codexModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(aiSettingsStatusProvider.notifier)
          .saveSettings(
            anthropicApiKey: _anthropicKey.text.trim().isEmpty
                ? null
                : _anthropicKey.text.trim(),
            openaiApiKey: _openaiKey.text.trim().isEmpty
                ? null
                : _openaiKey.text.trim(),
            preferredClaudeModel: _claudeModel.text.trim(),
            preferredCodexModel: _codexModel.text.trim(),
          );
      _anthropicKey.clear();
      _openaiKey.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI engine settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearKey({required bool anthropic}) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(aiSettingsStatusProvider.notifier)
          .saveSettings(
            clearAnthropicKey: anthropic,
            clearOpenaiKey: !anthropic,
          );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(aiSettingsStatusProvider).value ?? widget.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProviderCard(
          label: 'Claude',
          connected: status.hasAnthropicKey,
          keyController: _anthropicKey,
          keyHint: 'Anthropic API key',
          modelController: _claudeModel,
          modelHint: 'Model (e.g. claude-opus-5)',
          onClearKey: status.hasAnthropicKey
              ? () => _clearKey(anthropic: true)
              : null,
        ),
        const SizedBox(height: 18),
        _ProviderCard(
          label: 'Codex',
          connected: status.hasOpenaiKey,
          keyController: _openaiKey,
          keyHint: 'OpenAI API key',
          modelController: _codexModel,
          modelHint: 'Model (e.g. gpt-5-codex)',
          onClearKey: status.hasOpenaiKey
              ? () => _clearKey(anthropic: false)
              : null,
        ),
        const SizedBox(height: 24),
        StitchPrimaryButton(
          label: _saving ? 'Saving…' : 'Save',
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.label,
    required this.connected,
    required this.keyController,
    required this.keyHint,
    required this.modelController,
    required this.modelHint,
    required this.onClearKey,
  });

  final String label;
  final bool connected;
  final TextEditingController keyController;
  final String keyHint;
  final TextEditingController modelController;
  final String modelHint;
  final VoidCallback? onClearKey;

  @override
  Widget build(BuildContext context) => StitchCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (connected
                        ? AppColors.accentSuccess
                        : AppColors.textMuted)
                    .withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                connected ? 'KEY SET' : 'USING DESKTOP LOGIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: connected
                      ? AppColors.accentSuccess
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: keyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: keyHint,
            suffixIcon: onClearKey == null
                ? null
                : IconButton(
                    tooltip: 'Clear stored key',
                    icon: const Icon(Icons.close),
                    onPressed: onClearKey,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: modelController,
          decoration: InputDecoration(labelText: modelHint),
        ),
      ],
    ),
  );
}
