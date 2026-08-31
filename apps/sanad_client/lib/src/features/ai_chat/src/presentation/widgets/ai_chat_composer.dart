import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Text input for a user turn.
class AiChatComposer extends StatefulWidget {
  /// Creates the composer.
  const AiChatComposer({required this.onSend, super.key});

  /// Called with the trimmed, non-empty message text.
  final void Function(String text) onSend;

  @override
  State<AiChatComposer> createState() => _AiChatComposerState();
}

class _AiChatComposerState extends State<AiChatComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _canSend = false);
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: AppTextField(
                controller: _controller,
                hint: 'ai_chat.composer_hint'.tr(),
                textInputAction: TextInputAction.send,
                onChanged: (value) {
                  final canSend = value.trim().isNotEmpty;
                  if (canSend != _canSend) setState(() => _canSend = canSend);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
            AppButton(
              label: 'ai_chat.send'.tr(),
              size: AppButtonSize.small,
              onPressed: _canSend ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
