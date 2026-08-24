import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:text_optimization/src/presentation/cubit/text_optimization_cubit.dart';

/// Drop-in replacement for [AppDescriptionField] that also owns the shared
/// "Enhance with AI" flow (SAN-578).
///
/// Every description field that offers AI enhancement wires through this
/// widget instead of hand-rolling its own [TextOptimizationCubit] plumbing,
/// so loading/success/failure behavior — and the request itself — is
/// identical everywhere: Add Service, Edit Service, Request New Service,
/// Business Identity, and the RBAC role form.
class AiEnhanceDescriptionField extends StatefulWidget {
  const AiEnhanceDescriptionField({
    required this.label,
    required this.aiActionLabel,
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
    this.cubit,
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
  final int? maxLength;
  final bool showCharacterCount;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  /// Also invoked after a successful AI enhancement replaces the field's
  /// text, so callers that recompute completeness/dirty state from
  /// `onChanged` (rather than listening to the controller) stay correct.
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;

  /// Localized "Enhance with AI" button label.
  final String aiActionLabel;

  /// Overrides the [TextOptimizationCubit] resolved from `sl` — for tests
  /// that need to inject a fake without touching the service locator. The
  /// widget never closes a cubit supplied this way; the caller owns it.
  final TextOptimizationCubit? cubit;

  @override
  State<AiEnhanceDescriptionField> createState() =>
      _AiEnhanceDescriptionFieldState();
}

class _AiEnhanceDescriptionFieldState extends State<AiEnhanceDescriptionField> {
  late final TextOptimizationCubit _cubit =
      widget.cubit ?? sl<TextOptimizationCubit>();

  @override
  void dispose() {
    if (widget.cubit == null) _cubit.close();
    super.dispose();
  }

  void _handleOptimize() => _cubit.optimize(widget.controller?.text ?? '');

  void _handleState(BuildContext context, TextOptimizationState state) {
    switch (state.status) {
      case RequestStatus.success:
        final optimized = state.optimizedText;
        if (optimized != null) _applyOptimizedText(optimized);
        _cubit.acknowledge();
      case RequestStatus.failure:
        _showFailure(context, state.failure);
        _cubit.acknowledge();
      case RequestStatus.initial:
      case RequestStatus.loading:
        break;
    }
  }

  void _applyOptimizedText(String optimized) {
    final controller = widget.controller;
    if (controller != null) {
      controller.value = controller.value.copyWith(
        text: optimized,
        selection: TextSelection.collapsed(offset: optimized.length),
        composing: TextRange.empty,
      );
    }
    widget.onChanged?.call(optimized);
  }

  void _showFailure(BuildContext context, Failure? failure) {
    final display = failureErrorDisplay(
      failure,
      genericTitleKey: 'common.enhance_with_ai_error_title',
    );
    showAppSnackbar(
      context: context,
      title: display.title,
      caption: display.description,
      color: AppSnackbarColor.error,
      layout: AppSnackbarLayout.fullWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TextOptimizationCubit, TextOptimizationState>(
      bloc: _cubit,
      listener: _handleState,
      builder: (context, state) => AppDescriptionField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        label: widget.label,
        hint: widget.hint,
        errorText: widget.errorText,
        isRequired: widget.isRequired,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        showCharacterCount: widget.showCharacterCount,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        validator: widget.validator,
        inputFormatters: widget.inputFormatters,
        autovalidateMode: widget.autovalidateMode,
        aiActionLabel: widget.aiActionLabel,
        onImproveWithAi: widget.enabled ? _handleOptimize : null,
        isImprovingWithAi: state.isLoading,
      ),
    );
  }
}
