import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/client/error_mapper.dart';

void main() {
  DioException badResponse(int status, dynamic data) => DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );

  group('ErrorMapper — validation (EH-S1-01)', () {
    test('400 with message array maps to ValidationFailure with ALL messages',
        () {
      final failure = ErrorMapper.mapError(
        badResponse(400, <String, dynamic>{
          'message': <String>['Email is required', 'Password is too short'],
          'error': 'Bad Request',
          'statusCode': 400,
        }),
      );

      expect(failure, isA<ValidationFailure>());
      failure as ValidationFailure;
      expect(failure.messages, <String>[
        'Email is required',
        'Password is too short',
      ]);
      expect(failure.message, 'Email is required');
      expect(failure.code, '400');
      expect(failure.isValidation, isTrue);
    });

    test('400 with a single-message array still validates (length 1)', () {
      final failure = ErrorMapper.mapError(
        badResponse(400, <String, dynamic>{
          'message': <String>['Password is required'],
        }),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).messages, <String>[
        'Password is required',
      ]);
    });

    test('single-string 400 is a business rule -> BusinessRuleFailure', () {
      final failure = ErrorMapper.mapError(
        badResponse(400, <String, dynamic>{
          'message': 'Cannot delete the only branch',
          'error': 'Bad Request',
          'statusCode': 400,
        }),
      );

      expect(failure, isA<BusinessRuleFailure>());
      expect(failure, isNot(isA<ValidationFailure>()));
      expect(failure.message, 'Cannot delete the only branch');
      expect(failure.code, '400');
    });

    test('409 maps to ConflictFailure', () {
      final failure = ErrorMapper.mapError(
        badResponse(409, <String, dynamic>{'message': 'Already exists'}),
      );
      expect(failure, isA<ConflictFailure>());
      expect(failure.code, '409');
    });

    test('429 maps to RateLimitFailure', () {
      final failure = ErrorMapper.mapError(
        badResponse(429, <String, dynamic>{'message': 'Slow down'}),
      );
      expect(failure, isA<RateLimitFailure>());
      expect(failure.code, '429');
    });

    test('422 maps to ValidationFailure', () {
      final failure = ErrorMapper.mapError(
        badResponse(422, <String, dynamic>{'message': 'Unprocessable entity'}),
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('400 with an `errors` field map populates fieldErrors', () {
      final failure = ErrorMapper.mapError(
        badResponse(400, <String, dynamic>{
          'message': <String>['Validation failed'],
          'errors': <String, dynamic>{
            'email': <String>['must be an email'],
            'age': <String>['must be a positive number'],
          },
        }),
      );

      expect(failure, isA<ValidationFailure>());
      failure as ValidationFailure;
      expect(failure.fieldErrors, isNotNull);
      expect(failure.fieldErrors!['email'], <String>['must be an email']);
      expect(
        failure.fieldErrors!['age'],
        <String>['must be a positive number'],
      );
    });
  });

  group('ErrorMapper — status regressions', () {
    test('401 still maps to UnauthorizedFailure', () {
      final failure = ErrorMapper.mapError(
        badResponse(401, <String, dynamic>{
          'message': 'Authentication token is missing',
        }),
      );

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.code, '401');
    });

    test('404 still maps to ServerFailure preserving the server message', () {
      final failure = ErrorMapper.mapError(
        badResponse(404, <String, dynamic>{'message': 'Branch not found'}),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Branch not found');
      expect(failure.code, '404');
    });

    test('500 maps to ServerFailure', () {
      final failure = ErrorMapper.mapError(
        badResponse(500, <String, dynamic>{'message': 'boom'}),
      );

      expect(failure, isA<ServerFailure>());
    });
  });
}
