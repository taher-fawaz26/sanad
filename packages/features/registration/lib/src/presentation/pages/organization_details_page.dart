import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kIconSize = 48.0;

/// Step 4 (Organization path) — business + representative name entry.
///
/// Figma: `Organization` (`2142:14190`).
class OrganizationDetailsPage extends HookWidget {
  const OrganizationDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final businessNameController = useTextEditingController();
    final representativeNameController = useTextEditingController();
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSvgPicture.asset(
          AppSvgs.registrationOrganization,
          width: responsiveDimension(_kIconSize),
          height: responsiveDimension(_kIconSize),
          colorFilter: ColorFilter.mode(
            colors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        const RegistrationHeader(
          title: 'Organization Details',
          subtitle: Text(
            "Choose whether you're signing up as an Organization or an "
            'Individual.',
          ),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        AppTextField(
          controller: businessNameController,
          label: 'Business name',
          hint: 'Al Khaleej General Trading LLC',
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        AppTextField(
          controller: representativeNameController,
          label: 'Representative Name',
          hint: 'Ahmed Mohammed Al Mansouri',
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        AppButton(
          label: 'Continue',
          onPressed: () {
            context.push(RegistrationRoutes.identityVerification);
          },
        ),
      ],
    );
  }
}
