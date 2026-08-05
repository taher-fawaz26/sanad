import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organization_settings/src/presentation/bloc/contact_information/contact_information_bloc.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/add_or_change_email_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/add_or_change_phone_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/components/verified_email_field.dart';
import 'package:organization_settings/src/presentation/widgets/components/verified_phone_field.dart';

/// Section displaying the organization's contact info (phone + email).
///
/// Owns its own [ContactInformationBloc] — loads the current values on
/// mount, opens the per-field Add/Change sheets (which run the shared OTP
/// flow), and refreshes from the server once a field is verified.
class ContactInformationSection extends StatelessWidget {
  const ContactInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContactInformationBloc>(
      create: (_) =>
          sl<ContactInformationBloc>()..add(const ContactInformationLoaded()),
      child: const _ContactInformationView(),
    );
  }
}

class _ContactInformationView extends StatelessWidget {
  const _ContactInformationView();

  Future<void> _addOrChangePhone(BuildContext context, String? phone) async {
    final result = await showAddOrChangePhoneSheet(
      context: context,
      initialPhone: phone,
    );
    if (result == null || !context.mounted) return;
    context.read<ContactInformationBloc>().add(
      const ContactInformationRefreshed(),
    );
  }

  Future<void> _addOrChangeEmail(BuildContext context, String? email) async {
    final result = await showAddOrChangeEmailSheet(
      context: context,
      initialEmail: email,
    );
    if (result == null || !context.mounted) return;
    context.read<ContactInformationBloc>().add(
      const ContactInformationRefreshed(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactInformationBloc, ContactInformationState>(
      listener: (context, state) {
        if (state.status == RequestStatus.failure && state.failure != null) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure!.message,
          );
        }
      },
      builder: (context, state) {
        return AppSectionCard(
          title: 'settings.section_contact'.tr(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VerifiedPhoneField(
                phone: state.phone,
                verified: state.phoneVerified,
                onAdd: () => _addOrChangePhone(context, state.phone),
                onChange: () => _addOrChangePhone(context, state.phone),
              ),
              SizedBox(height: AppSpacing.md),
              VerifiedEmailField(
                email: state.email,
                verified: state.emailVerified,
                onAdd: () => _addOrChangeEmail(context, state.email),
                onChange: () => _addOrChangeEmail(context, state.email),
              ),
            ],
          ),
        );
      },
    );
  }
}
