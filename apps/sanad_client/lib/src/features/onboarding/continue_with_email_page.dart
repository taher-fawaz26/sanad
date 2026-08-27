import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

/// Continue with Email (Figma `6979:27423`).
///
/// UI-only for this phase: email validity is checked locally, but there is
/// no backend to submit to yet, so the Next action is a documented no-op.
/// The `Form`-less controller+hook validation mirrors `packages/auth`'s
/// `EmailOtpPage` pattern (a single derived boolean has no async
/// lifecycle, so it doesn't need a Bloc/Cubit per state-management.md).
class ContinueWithEmailPage extends HookWidget {
  /// Creates a [ContinueWithEmailPage].
  const ContinueWithEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final controller = useTextEditingController();
    final isValid = useState(false);

    useEffect(() {
      void listener() =>
          isValid.value = EmailValidator.isValid(controller.text.trim());
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    void onNext() {
      // TODO(onboarding-phase-2): wire to the real continue-with-email flow
      // once the backend/OTP endpoint exists — no-op placeholder for this
      // UI-only phase.
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(AppSpacing.xxl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrolls instead of overflowing on short screens — the Next
              // button below stays pinned regardless of content height.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: responsiveDimension(AppSpacing.md)),
                      Container(
                        width: responsiveDimension(56),
                        height: responsiveDimension(56),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: AppRadius.circularXl,
                        ),
                        child: Center(
                          child: AppSvgPicture.asset(
                            AppSvgs.sendMail,
                            width: responsiveDimension(AppDimension.iconMenu),
                            height: responsiveDimension(
                              AppDimension.iconMenu,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.lg)),
                      Text(
                        'onboarding.email_title'.tr(),
                        style: typography.title1.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xs)),
                      Text(
                        'onboarding.email_subtitle'.tr(),
                        style: typography.regularNormal.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xxl)),
                      AppTextField(
                        controller: controller,
                        label: 'onboarding.email_label'.tr(),
                        hint: 'onboarding.email_hint'.tr(),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (isValid.value) onNext();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              AppPageEntrance(
                distance: 10,
                child: AppButton(
                  label: 'onboarding.next'.tr(),
                  onPressed: isValid.value ? onNext : null,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }
}
