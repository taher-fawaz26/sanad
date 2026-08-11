import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/invitation/src/routes/invitation_routes.dart';

void main() {
  group('InvitationRoutes', () {
    test('details, otp, and success are distinct, well-formed paths', () {
      expect(InvitationRoutes.details, '/invitation/:token');
      expect(InvitationRoutes.otp, '/invitation/otp');
      expect(InvitationRoutes.success, '/invitation/success');

      final all = {
        InvitationRoutes.details,
        InvitationRoutes.otp,
        InvitationRoutes.success,
      };
      expect(all, hasLength(3), reason: 'route paths must be unique');
    });

    test('detailsPath substitutes the token into the concrete path', () {
      expect(
        InvitationRoutes.detailsPath('abc-123'),
        '/invitation/abc-123',
      );
    });
  });
}
