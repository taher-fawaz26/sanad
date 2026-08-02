import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/models/onboarding_args.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/routes/registration_routes.dart';

class SelectAccountTypePage extends HookWidget {
  const SelectAccountTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = useState<RegistrationAccountType?>(null);

    // Seed the verified email + onboarding token handed over by the auth OTP
    // flow (this is the first registration step for a new user).
    final extra = GoRouterState.of(context).extra;
    useEffect(() {
      if (extra is OnboardingArgs) {
        context.read<RegistrationCubit>().setOnboarding(
          email: extra.email,
          onboardingToken: extra.onboardingToken,
        );
      }
      return null;
    }, [extra]);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegistrationHeader(
                  title: 'registration.account_type_title'.tr(),
                  subtitle: Text('registration.account_type_subtitle'.tr()),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                _AccountTypeCard(
                  title: 'registration.organization'.tr(),
                  description: 'registration.organization_desc'.tr(),
                  iconPath: AppSvgs.registrationOrganization,
                  type: RegistrationAccountType.organization,
                  selected: selected.value,
                  onTap: () =>
                      selected.value = RegistrationAccountType.organization,
                ),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
                _AccountTypeCard(
                  title: 'registration.individual'.tr(),
                  description: 'registration.individual_desc'.tr(),
                  iconPath: AppSvgs.registrationIndividual,
                  type: RegistrationAccountType.individual,
                  selected: selected.value,
                  onTap: () =>
                      selected.value = RegistrationAccountType.individual,
                ),
                SizedBox(height: responsiveDimension(AppSpacing.lg)),
                AppButton(
                  label: 'registration.continue'.tr(),
                  onPressed: selected.value == null
                      ? null
                      : () {
                          final type = selected.value!;
                          context.read<RegistrationCubit>().setAccountType(
                            type,
                          );
                          context.push(
                            type == RegistrationAccountType.organization
                                ? RegistrationRoutes.organizationDetails
                                : RegistrationRoutes.individualDetails,
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final String iconPath;
  final RegistrationAccountType type;
  final RegistrationAccountType? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    final colors = context.appColors;
    final typography = context.appTypography;
    final accentColor = isSelected ? colors.link : colors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary50 : colors.gray50,
          border: Border.all(
            color: isSelected ? colors.primary : colors.slate100,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimension.radiusProfileCard),
        ),
        child: Column(
          children: [
            Column(
              children: [
                AppSvgPicture.asset(
                  iconPath,
                  width: AppDimension.iconMenu,
                  height: AppDimension.iconMenu,
                  colorFilter: ColorFilter.mode(
                    accentColor,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: typography.regularNormal.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 16 / 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              description,
              textAlign: TextAlign.center,
              style: typography.tinyNormal.copyWith(
                height: 16 / 12,
                color: colors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
