import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/theme.dart';

class ComposerBar extends StatefulWidget {
  const ComposerBar({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.placeholder = 'Reply to this task...',
  });

  final ValueChanged<String> onSend;
  final bool enabled;
  final String placeholder;

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (!widget.enabled || value.isEmpty) {
      return;
    }
    widget.onSend(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('composer-bar'),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgInput,
            child: IconButton(
              onPressed: widget.enabled ? () {} : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.textPrimary,
            child: IconButton(
              onPressed: widget.enabled ? _submit : null,
              icon: const Icon(Icons.send_rounded, color: AppColors.bgPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
