import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/mappers/document_field_name_resolver.dart';

/// EasyLocalization is intentionally not initialized: `.tr()` falls back to
/// returning the raw key (see `individual_details_page_test.dart`), so
/// assertions target the resolved i18n key, not display copy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveDocumentFieldLabel', () {
    test('maps known Emirates ID backend identifiers to their l10n keys', () {
      expect(
        resolveDocumentFieldLabel('full_name_english'),
        'registration.full_name_en',
      );
      expect(
        resolveDocumentFieldLabel('fullNameArabic'),
        'registration.full_name_ar',
      );
      expect(resolveDocumentFieldLabel('id_number'), 'registration.id_number');
      expect(
        resolveDocumentFieldLabel('DATE_OF_BIRTH'),
        'registration.date_of_birth',
      );
      expect(
        resolveDocumentFieldLabel('expiry_date'),
        'registration.expiry_date',
      );
      expect(resolveDocumentFieldLabel('gender'), 'registration.gender');
      expect(
        resolveDocumentFieldLabel('nationality'),
        'registration.nationality',
      );
    });

    test('maps known trade licence backend identifiers to their l10n keys', () {
      expect(
        resolveDocumentFieldLabel('license_number'),
        'registration.licence_no',
      );
      expect(
        resolveDocumentFieldLabel('licenseNumber'),
        'registration.licence_no',
      );
      expect(
        resolveDocumentFieldLabel('unified_registration_number'),
        'registration.unified_reg_no',
      );
    });

    test('never returns the raw backend identifier for an unknown field', () {
      final result = resolveDocumentFieldLabel('some_unmapped_field');
      expect(result, isNot('some_unmapped_field'));
      expect(result, 'Some Unmapped Field');
    });
  });

  group('describeMissingFields', () {
    test('resolves and deduplicates aliased fields', () {
      final withAlias = describeMissingFields([
        'license_number',
        'licenseNumber',
        'id_number',
      ]);
      final withoutAlias = describeMissingFields([
        'license_number',
        'id_number',
      ]);

      // license_number/licenseNumber resolve to the same label, so aliasing
      // the same field a second time must not change the result.
      expect(withAlias, withoutAlias);
      expect(
        withAlias
            .split('registration.field_list_separator')
            .where((s) => s.isNotEmpty)
            .length,
        2,
      );
    });

    test('empty input yields an empty string', () {
      expect(describeMissingFields(const []), '');
    });
  });
}
