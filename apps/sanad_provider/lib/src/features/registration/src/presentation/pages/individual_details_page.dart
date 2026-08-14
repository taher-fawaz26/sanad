import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/cubit/registration_details_cubit.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/registration_flow_context_x.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_header.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';

const _kIconSize = 48.0;

/// Step 4 (Individual path) — full name entry.
///
/// Figma: `individule` (`2142:14216`). Individuals continue through Emirates ID
/// verification before reaching the dashboard.
class IndividualDetailsPage extends HookWidget {
  const IndividualDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<RegistrationDetailsCubit>().state;
    final fullNameController = useTextEditingController(text: state.fullName);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final colors = context.appColors;

    void submit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      context.read<RegistrationDetailsCubit>().setFullName(
        fullNameController.text.trim(),
      );
      context
        ..syncDocumentFlowContext()
        ..push(RegistrationRoutes.identityVerification);
    }

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSvgPicture.asset(
              AppSvgs.registrationProfile,
              width: responsiveDimension(_kIconSize),
              height: responsiveDimension(_kIconSize),
              colorFilter: ColorFilter.mode(
                colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
            RegistrationHeader(
              title: 'registration.individual_details_title'.tr(),
              subtitle: Text('registration.individual_details_subtitle'.tr()),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
            AppTextField(
              controller: fullNameController,
              label: 'registration.full_name'.tr(),
              hint: 'registration.full_name_hint'.tr(),
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (!RequiredValidator.isValid(value)) {
                  return 'registration.field_required'.tr();
                }
                if (!LengthValidator.isValid(
                  value,
                  minLength: 3,
                  maxLength: 255,
                )) {
                  return 'registration.name_length_error'.tr(
                    namedArgs: {'min': '3', 'max': '255'},
                  );
                }
                return null;
              },
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
