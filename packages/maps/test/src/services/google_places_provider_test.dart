import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/src/services/google_places_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late GooglePlacesProvider provider;

  setUp(() {
    dio = _MockDio();
    provider = GooglePlacesProvider(apiKey: 'key', dio: dio);
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: 'autocomplete'),
        statusCode: 200,
        data: {'status': 'ZERO_RESULTS'},
      ),
    );
  });

  test('autocomplete restricts results to the configured country', () async {
    await provider.autocomplete(query: 'marina').run();

    final params =
        verify(
              () => dio.get<Map<String, dynamic>>(
                any(),
                queryParameters: captureAny(named: 'queryParameters'),
              ),
            ).captured.first
            as Map<String, dynamic>;

    expect(params['components'], 'country:ae');
    expect(params['region'], 'ae');
  });
}
