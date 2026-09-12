import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The two confirmations Conversation History's swipe actions open — Figma
/// `8516:32425` (Delete conversation) and `8516:32435` (Rename Conversation).
///
/// Both go through [showAppDialog], which is the app's single dialog entry
/// point: one surface, one barrier, one enter/exit animation
/// (`showAppAnimatedDialog`'s fade + 0.94 scale on `AppMotionDuration.quick`),
/// one set of paddings. Nothing here builds a dialog of its own, and nothing
/// here names a duration — delete and rename cannot drift apart because
/// neither owns anything that could drift.
///
/// They are free functions rather than a widget because a confirmation is a
/// *question*, not a piece of the screen: the caller awaits an answer and acts
/// on it, and there is no state to keep between asking and answering.
abstract final class ConversationHistoryDialogs {
  ConversationHistoryDialogs._();

  /// Asks whether to delete the conversation. `true` means the user confirmed.
  ///
  /// Figma's copy is deliberately specific about scope ("from your side"), so
  /// it is one key rather than a generic delete confirmation borrowed from
  /// elsewhere.
  static Future<bool> confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'history.delete_conversation_title'.tr(),
      description: 'history.delete_conversation_description'.tr(),
      // Figma's task modals read as a short form, not an alert: the copy sits
      // on the leading edge rather than centred.
      alignment: AppPopoverAlignment.start,
      primaryLabel: 'common.delete'.tr(),
      // The red CTA — `AppButtonIntent.destructive`, the same token the swipe
      // action's own colour comes from, so the affordance and its
      // confirmation cannot disagree about how serious this is.
      primaryDestructive: true,
      onPrimary: () => navigator.pop(true),
      secondaryLabel: 'common.cancel'.tr(),
      secondaryOutlined: true,
    );

    // Null covers both Cancel and a barrier tap, which mean the same thing.
    return confirmed ?? false;
  }

  /// Asks for a new name, pre-filled from [controller].
  ///
  /// The controller is the **caller's**, not one made here. A controller
  /// created alongside the dialog would have to be disposed when the future
  /// completes — which is the moment the dialog starts its exit transition,
  /// not the moment it finishes one, so the still-mounted field would read a
  /// disposed controller for the length of the animation. Owning it on the
  /// screen sidesteps the race entirely and costs one field.
  ///
  /// Returns the trimmed new name, or `null` when the user cancelled **or**
  /// left it unchanged/blank — all three mean "do nothing", and collapsing
  /// them here keeps that decision out of the caller.
  static Future<String?> requestRename(
    BuildContext context, {
    required TextEditingController controller,
    required String currentName,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    controller.text = currentName;

    final result = await showAppDialog<String>(
      context: context,
      title: 'history.rename_conversation_title'.tr(),
      description: 'history.rename_conversation_description'.tr(),
      alignment: AppPopoverAlignment.start,
      // The variant that puts a field between the copy and the buttons —
      // the design system already has it (`40:10048`), so the field is
      // `AppTextField` with its own label, not a bespoke input.
      actions: AppPopoverActions.textInput,
      textFieldController: controller,
      textFieldLabel: 'history.rename_conversation_field_label'.tr(),
      textFieldHint: 'history.rename_conversation_field_hint'.tr(),
      primaryLabel: 'history.rename'.tr(),
      onPrimary: () => navigator.pop(controller.text),
      secondaryLabel: 'common.cancel'.tr(),
      secondaryOutlined: true,
    );

    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == currentName) {
      return null;
    }
    return trimmed;
  }
}
