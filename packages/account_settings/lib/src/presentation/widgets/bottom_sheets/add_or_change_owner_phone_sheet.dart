import 'package:contact_verification/contact_verification.dart';
import 'package:flutter/widgets.dart';

/// Shows the add/change sheet for the signed-in owner's own phone number.
///
/// A thin binding over the shared [showContactChangeSheet] - the four contact
/// flows differ only in field type and verification purpose, so the sheet
/// itself lives in `contact_verification` and is not duplicated here.
Future<String?> showAddOrChangeOwnerPhoneSheet({
  required BuildContext context,
  String? initialPhone,
}) {
  return showContactChangeSheet(
    context: context,
    field: ContactField.phone,
    purpose: VerificationPurpose.changeOwnerPhone,
    initialValue: initialPhone,
  );
}
