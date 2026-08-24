import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_ui/src/widgets/app_enhance_with_ai_button.dart';

/// Canonical application-wide description / multiline-text field.
///
/// Wraps [AppTextField] with the shared "Enhance with AI" affordance
/// ([AppEnhanceWithAiButton]) and an optional live character counter, so
/// every description field in the app shares one visual language. This
/// widget is pure presentation: validation rules, required-ness, max
/// length, and AI orchestration are all supplied by the caller.
class AppDescriptionField extends StatelessWidget {
  const AppDescriptionField({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 5,
    this.maxLength,
    this.showCharacterCount = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.aiActionLabel,
    this.onImproveWithAi,
    this.isImprovingWithAi = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final String? errorText;
  final bool isRequired;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;

  /// Feature-supplied character limit — drives the counter only. The actual
  /// enforcement stays in [validator]/[inputFormatters].
  final int? maxLength;
  final bool showCharacterCount;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;

  /// Localized "Enhance with AI" label. When `null`, the AI action is
  /// omitted entirely.
  final String? aiActionLabel;

  /// Callback for the AI action. When `null`, the button renders disabled.
  final VoidCallback? onImproveWithAi;

  /// Whether the AI action is currently running.
  final bool isImprovingWithAi;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;

    // The field always renders at its fixed `maxLines` height (see
    // `AppTextField._multilineFieldHeight`: `minLines == maxLines`), so a
    // button overlaid on top of it — instead of laid out below it — end up
    // sitting wherever the typed text currently reaches, overlapping once
    // the content grows past a couple of lines. Laying the button out as a
    // normal flow sibling underneath keeps a guaranteed gap regardless of
    // how many lines are filled.
    final fieldColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: controller,
          focusNode: focusNode,
          label: label,
          hint: hint,
          errorText: errorText,
          isRequired: isRequired,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          validator: validator,
          inputFormatters: inputFormatters,
          autovalidateMode: autovalidateMode,
        ),
        if (aiActionLabel != null) ...[
          SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppEnhanceWithAiButton(
              label: aiActionLabel!,
              onTap: enabled ? onImproveWithAi : null,
              isLoading: isImprovingWithAi,
            ),
          ),
        ],
      ],
    );

    if (!showCharacterCount || maxLength == null || controller == null) {
      return fieldColumn;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        fieldColumn,
        SizedBox(height: AppSpacing.xs),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final typography = context.appTypography;
            final colors = context.appColors;
            final brightness = Theme.of(context).brightness;
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${value.text.length}/$maxLength',
                style: FieldTokens.captionStyle(typography, colors, brightness),
              ),
            );
          },
        ),
      ],
    );
  }
}
