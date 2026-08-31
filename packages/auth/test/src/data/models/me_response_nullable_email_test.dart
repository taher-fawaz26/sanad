import 'package:auth/src/data/models/responses/me_response_dto.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeResponseModel.fromJson email nullability', () {
    test('parses a phone-only client whose email is null', () {
      final model = MeResponseModel.fromJson(const {
        'id': 'client-1',
        'name': null,
        'email': null,
        'userType': 'client',
        'permissions': <String>[],
      });

      expect(model.email, isNull);
      expect(model.name, isNull);
      expect(model.userType, UserType.client);
    });

    test('still parses a present email', () {
      final model = MeResponseModel.fromJson(const {
        'id': 'client-2',
        'email': 'user@example.com',
        'userType': 'client',
        'permissions': <String>[],
      });

      expect(model.email, 'user@example.com');
    });
  });
}
