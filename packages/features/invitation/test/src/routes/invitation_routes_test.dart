import 'package:flutter_test/flutter_test.dart';
import 'package:invitation/src/routes/invitation_routes.dart';

void main() {
  group('InvitationRoutes', () {
    test('details, otp, and success are distinct, well-formed paths', () {
      expect(InvitationRoutes.details, '/invitation-demo');
      expect(InvitationRoutes.otp, '/invitation-demo/otp');
      expect(InvitationRoutes.success, '/invitation-demo/success');

      final all = {
        InvitationRoutes.details,
        InvitationRoutes.otp,
        InvitationRoutes.success,
      };
      expect(all, hasLength(3), reason: 'route paths must be unique');
    });
  });
}
