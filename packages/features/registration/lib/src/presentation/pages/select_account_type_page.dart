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

    return Column(
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
          onTap: () => selected.value = RegistrationAccountType.organization,
        ),
        SizedBox(height: responsiveDimension(AppSpacing.lg)),
        _AccountTypeCard(
          title: 'registration.individual'.tr(),
          description: 'registration.individual_desc'.tr(),
          iconPath: AppSvgs.registrationIndividual,
          type: RegistrationAccountType.individual,
          selected: selected.value,
          onTap: () => selected.value = RegistrationAccountType.individual,
        ),
        const Spacer(),
        AppButton(
          label: 'registration.continue'.tr(),
          onPressed: selected.value == null
              ? null
              : () {
                  final type = selected.value!;
                  context.read<RegistrationCubit>().setAccountType(type);
                  context.push(
                    type == RegistrationAccountType.organization
                        ? RegistrationRoutes.organizationDetails
                        : RegistrationRoutes.individualDetails,
                  );
                },
        ),
      ],
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: responsiveDimension(AppSpacing.xl),
          vertical: responsiveDimension(AppSpacing.lg),
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.circularMd,
        ),
        child: Column(
          children: [
            AppSvgPicture.asset(
              iconPath,
              width: responsiveDimension(28),
              height: responsiveDimension(28),
              colorFilter: ColorFilter.mode(
                isSelected ? colors.primary : colors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.sm)),
            Text(
              title,
              style: typography.regularNormal.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: responsiveDimension(4)),
            Text(
              description,
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
