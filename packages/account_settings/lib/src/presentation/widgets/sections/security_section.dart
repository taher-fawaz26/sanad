import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Security section of Account Settings — the app-lock (biometric unlock)
/// toggle.
class SecuritySection extends StatelessWidget {
  const SecuritySection({
    required this.enabled,
    required this.capability,
    super.key,
    this.availableBiometrics = const [],
    this.busy = false,
    this.onToggle,
  });

  /// The persisted preference. Never optimistic — it flips only after the OS
  /// has authenticated the user.
  final bool enabled;

  final AppLockCapability capability;

  /// Enrolled methods, used only to word the caption.
  final List<BiometricType> availableBiometrics;

  /// An enable/disable is in flight; the switch shows a spinner in its knob
  /// and holds its previous value.
  final bool busy;

  final ValueChanged<bool>? onToggle;

  bool get _supported => capability == AppLockCapability.available;

  /// Explanatory copy follows the enrolled biometric purely so the section
  /// reads naturally ("Face ID" vs "fingerprint"). The feature itself never
  /// depends on a particular method being present — the device passcode is
  /// always an acceptable credential.
  String get _caption {
    if (!_supported) return 'settings.app_lock_caption_unsupported'.tr();
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'settings.app_lock_caption_face'.tr();
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'settings.app_lock_caption_fingerprint'.tr();
    }
    return 'settings.app_lock_caption_generic'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_security'.tr(),
      // The explanation goes in the card subtitle rather than the row's
      // `caption` slot: `AppTableCell` gives a captioned row a fixed 40dp box
      // for 20 + 4 + 16 of text, and because font size and box height scale by
      // different ratios it overflows. Nothing else in the app passes
      // `caption` to an `AppTableRow`, so this is not a regression to fix
      // here.
      subtitle: _caption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTableRow(
            title: 'settings.app_lock'.tr(),
            trailing: AppTableTrailing.switchControl,
            switchValue: enabled,
            switchLoading: busy,
            // A device with no screen lock has nothing to authenticate
            // against, so the control is inert rather than raising a prompt
            // that cannot succeed.
            onSwitchChanged: _supported ? onToggle : null,
          ),
        ],
      ),
    );
  }
}
