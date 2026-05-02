import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/shared/widgets/template_kit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit([String? promptOverride]) async {
    final prompt = (promptOverride ?? _controller.text).trim();
    if (prompt.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final task = await ref
          .read(homeTasksProvider.notifier)
          .createTask(prompt);
      _controller.clear();
      if (mounted) {
        context.go('/session/${task.id}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplateScaffold(
      key: const Key('home-screen'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

          return Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TemplateStatusBar(),
              ),
              Positioned(
                top: 59,
                left: 0,
                right: 0,
                child: TemplateNavBar(
                  onLeadingTap: () => context.go('/home/recents'),
                  onTitleTap: () => context.go('/account'),
                  onTrailingTap: () => FocusScope.of(context).requestFocus(),
                ),
              ),
              Positioned(
                top: (height * 0.44).clamp(260.0, 363.0),
                left: (width - 46) / 2,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 46,
                        height: 46,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const PhodexBadge(),
              ),
              Positioned(
                left: 16,
                right: 0,
                bottom: bottomInset + 101,
                child: _PromptExamplesLive(onSubmit: _submit),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: bottomInset + 20,
                child: _LiveComposer(
                  controller: _controller,
                  enabled: !_isSubmitting,
                  onSubmit: () => _submit(),
                  onFolderTap: () => context.go('/repos'),
                  onHeadphonesTap: () => context.go('/approvals'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PromptExamplesLive extends StatelessWidget {
  const _PromptExamplesLive({required this.onSubmit});

  final Future<void> Function(String prompt) onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          PromptCard(
            title: 'Design a database schema',
            subtitle: 'for an online merch store',
            onTap: () =>
                onSubmit('Design a database schema for an online merch store.'),
          ),
          const SizedBox(width: 12),
          PromptCard(
            title: 'Explain airplane',
            subtitle: 'to someone 5 years old',
            onTap: () => onSubmit('Explain airplane turbulence to a child.'),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _LiveComposer extends StatelessWidget {
  const _LiveComposer({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    required this.onFolderTap,
    required this.onHeadphonesTap,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;
  final VoidCallback onFolderTap;
  final VoidCallback onHeadphonesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TemplateIcon(icon: Icons.photo_camera_outlined),
        const SizedBox(width: 20),
        const TemplateIcon(icon: Icons.image_outlined),
        const SizedBox(width: 20),
        TemplateIcon(icon: Icons.folder_outlined, onTap: onFolderTap),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: TemplateColors.separator),
              borderRadius: BorderRadius.circular(32),
            ),
            child: TextField(
              key: const Key('home-composer-field'),
              controller: controller,
              enabled: enabled,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(
                color: TemplateColors.labelPrimary,
                fontSize: 17,
                height: 22 / 17,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Message',
                hintStyle: TextStyle(
                  color: TemplateColors.labelTertiary,
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        TemplateIcon(
          icon: enabled ? Icons.arrow_upward_rounded : Icons.hourglass_empty,
          onTap: enabled ? onSubmit : null,
        ),
        const SizedBox(width: 12),
        TemplateIcon(icon: Icons.headphones_rounded, onTap: onHeadphonesTap),
      ],
    );
  }
}
