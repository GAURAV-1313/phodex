import 'package:flutter/material.dart';

class TemplateColors {
  const TemplateColors._();

  static const labelPrimary = Color(0xFF000000);
  static const labelSecondary = Color(0x993C3C43);
  static const labelTertiary = Color(0x4D3C3C3C);
  static const separator = Color(0xFFE5E5EA);
  static const groupedBackground = Color(0xFFF2F2F7);
  static const promptBackground = Color(0xFFF6F6F6);
}

class TemplateScaffold extends StatelessWidget {
  const TemplateScaffold({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.bottomSafeArea = false,
  });

  final Widget child;
  final Color backgroundColor;
  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(bottom: bottomSafeArea, child: child),
    );
  }
}

class TemplateStatusBar extends StatelessWidget {
  const TemplateStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 59,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(52, 0, 28, 0),
        child: Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '9:41',
                  style: TextStyle(
                    color: TemplateColors.labelPrimary,
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _CellularIcon(),
                SizedBox(width: 7),
                Icon(Icons.wifi_rounded, color: Colors.black, size: 19),
                SizedBox(width: 7),
                _BatteryIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TemplateNavBar extends StatelessWidget {
  const TemplateNavBar({
    super.key,
    this.title = 'Phodex',
    this.leading = Icons.menu_rounded,
    this.trailing = Icons.edit_square,
    this.trailingColor = const Color(0xFFC7C7CC),
    this.showModel = true,
    this.onLeadingTap,
    this.onTitleTap,
    this.onTrailingTap,
  });

  final String title;
  final IconData leading;
  final IconData trailing;
  final Color trailingColor;
  final bool showModel;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTitleTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: TemplateIcon(icon: leading, onTap: onLeadingTap),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTitleTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TemplateColors.labelPrimary,
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showModel) ...const [
                  SizedBox(width: 4),
                  Text(
                    '4',
                    style: TextStyle(
                      color: TemplateColors.labelSecondary,
                      fontSize: 17,
                      height: 22 / 17,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: TemplateColors.labelSecondary,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 20,
            child: TemplateIcon(
              icon: trailing,
              color: trailingColor,
              onTap: onTrailingTap,
            ),
          ),
        ],
      ),
    );
  }
}

class TemplateIcon extends StatelessWidget {
  const TemplateIcon({
    super.key,
    required this.icon,
    this.color = TemplateColors.labelPrimary,
    this.size = 24,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}

class PhodexBadge extends StatelessWidget {
  const PhodexBadge({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.52,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class PromptExamples extends StatelessWidget {
  const PromptExamples({super.key, this.onPromptTap});

  final VoidCallback? onPromptTap;

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
            onTap: onPromptTap,
          ),
          const SizedBox(width: 12),
          PromptCard(
            title: 'Explain airplane',
            subtitle: 'to someone 5 years old',
            onTap: onPromptTap,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class PromptCard extends StatelessWidget {
  const PromptCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: TemplateColors.promptBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TemplateColors.labelPrimary,
                fontSize: 16,
                height: 21 / 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TemplateColors.labelSecondary,
                fontSize: 16,
                height: 21 / 16,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemplateComposerBar extends StatelessWidget {
  const TemplateComposerBar({
    super.key,
    this.message = 'Message',
    this.compact = false,
    this.showLeadingActions = true,
    this.showSubmit = false,
    this.onCameraTap,
    this.onImageTap,
    this.onFolderTap,
    this.onMessageTap,
    this.onHeadphonesTap,
    this.onSubmitTap,
  });

  final String message;
  final bool compact;
  final bool showLeadingActions;
  final bool showSubmit;
  final VoidCallback? onCameraTap;
  final VoidCallback? onImageTap;
  final VoidCallback? onFolderTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onHeadphonesTap;
  final VoidCallback? onSubmitTap;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          _RoundIcon(icon: Icons.add_rounded, onTap: onFolderTap),
          const SizedBox(width: 14),
          Expanded(
            child: MessageField(message: message, onTap: onMessageTap),
          ),
          const SizedBox(width: 12),
          if (showSubmit)
            _RoundIcon(
              icon: Icons.arrow_upward_rounded,
              filled: true,
              onTap: onSubmitTap,
            )
          else
            _RoundIcon(icon: Icons.graphic_eq_rounded, onTap: onSubmitTap),
        ],
      );
    }

    return Row(
      children: [
        if (showLeadingActions) ...[
          TemplateIcon(icon: Icons.photo_camera_outlined, onTap: onCameraTap),
          const SizedBox(width: 20),
          TemplateIcon(icon: Icons.image_outlined, onTap: onImageTap),
          const SizedBox(width: 20),
          TemplateIcon(icon: Icons.folder_outlined, onTap: onFolderTap),
          const SizedBox(width: 20),
        ],
        Expanded(
          child: MessageField(message: message, onTap: onMessageTap),
        ),
        const SizedBox(width: 14),
        TemplateIcon(icon: Icons.headphones_rounded, onTap: onHeadphonesTap),
      ],
    );
  }
}

class MessageField extends StatelessWidget {
  const MessageField({
    super.key,
    this.message = 'Message',
    this.showMic = true,
    this.onTap,
  });

  final String message;
  final bool showMic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 38,
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.only(left: 14, right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TemplateColors.separator),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: message == 'Message'
                      ? TemplateColors.labelTertiary
                      : TemplateColors.labelPrimary,
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
            ),
            if (showMic)
              const Icon(
                Icons.keyboard_voice_outlined,
                color: Color(0xFF8E8E93),
                size: 21,
              ),
          ],
        ),
      ),
    );
  }
}

class MockKeyboard extends StatelessWidget {
  const MockKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Container(
      height: 329,
      padding: const EdgeInsets.fromLTRB(3, 10, 3, 8),
      color: const Color(0xFFD1D4DA),
      child: Column(
        children: [
          for (final row in keys) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final keyLabel in row)
                  Container(
                    width: 33,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 1),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      keyLabel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _keyboardUtility('123', width: 46),
              Expanded(child: _keyboardUtility('space')),
              _keyboardUtility('return', width: 72),
            ],
          ),
          const Spacer(),
          Container(
            width: 134,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyboardUtility(String label, {double? width}) {
    return Container(
      height: 42,
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFABB0BA),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(children: children),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.destructive = false,
    this.showChevron = false,
    this.showDivider = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final bool destructive;
  final bool showChevron;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF3B30)
        : TemplateColors.labelPrimary;

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      height: 22 / 17,
                    ),
                  ),
                ),
                if (value != null)
                  Flexible(
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: TemplateColors.labelSecondary,
                        fontSize: 17,
                        height: 22 / 17,
                      ),
                    ),
                  ),
                if (showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: TemplateColors.labelSecondary,
                    size: 18,
                  ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 54),
            child: Divider(height: 0.4, color: TemplateColors.separator),
          ),
      ],
    );
  }
}

class SectionCaption extends StatelessWidget {
  const SectionCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 8),
      child: Text(
        text.toLowerCase(),
        style: const TextStyle(
          color: TemplateColors.labelSecondary,
          fontSize: 15,
          height: 22 / 15,
        ),
      ),
    );
  }
}

class ChatMessageBlock extends StatelessWidget {
  const ChatMessageBlock({
    super.key,
    required this.author,
    required this.body,
    required this.assistant,
  });

  final String author;
  final String body;
  final bool assistant;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        assistant
            ? const PhodexBadge(size: 25)
            : Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7902F),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                style: const TextStyle(
                  color: TemplateColors.labelPrimary,
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                body,
                style: const TextStyle(
                  color: TemplateColors.labelPrimary,
                  fontSize: 17,
                  height: 27 / 17,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.filled = false, this.onTap});

  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? Colors.black : const Color(0xFFF2F2F7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
    );
  }
}

class _CellularIcon extends StatelessWidget {
  const _CellularIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 19,
      height: 13,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == 3 ? 0 : 2),
            child: Container(
              width: 3,
              height: 4.0 + index * 3,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  const _BatteryIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 14,
      child: Row(
        children: [
          Container(
            width: 25,
            height: 14,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(4.3),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(width: 1),
          Container(
            width: 1.3,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
