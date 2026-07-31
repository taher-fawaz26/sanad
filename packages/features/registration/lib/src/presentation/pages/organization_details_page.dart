import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
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
    final state = context.read<RegistrationCubit>().state;
    final businessNameController =
        useTextEditingController(text: state.businessName);
    final representativeNameController =
        useTextEditingController(text: state.representativeName);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final colors = context.appColors;

    String? required(String? value) =>
        (value == null || value.trim().isEmpty)
            ? 'registration.field_required'.tr()
            : null;

    void submit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      context.read<RegistrationCubit>().setOrganizationDetails(
            businessName: businessNameController.text.trim(),
            representativeName: representativeNameController.text.trim(),
          );
      context.push(RegistrationRoutes.identityVerification);
    }

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          AppSvgPicture.asset(
            AppSvgs.registrationCity,
            width: responsiveDimension(_kIconSize),
            height: responsiveDimension(_kIconSize),
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
          RegistrationHeader(
            title: 'registration.org_details_title'.tr(),
            subtitle: Text('registration.org_details_subtitle'.tr()),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
          AppTextField(
            controller: businessNameController,
            label: 'registration.business_name'.tr(),
            hint: 'registration.business_name_hint'.tr(),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: required,
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
          AppTextField(
            controller: representativeNameController,
            label: 'registration.representative_name'.tr(),
            hint: 'registration.representative_name_hint'.tr(),
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: required,
            onSubmitted: (_) => submit(),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
          AppButton(
            label: 'registration.continue'.tr(),
            onPressed: submit,
          ),
        ],
        ),
      ),
    );
  }
}
