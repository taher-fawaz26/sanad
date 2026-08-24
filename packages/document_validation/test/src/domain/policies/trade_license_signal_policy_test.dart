import 'package:document_validation/src/domain/policies/trade_license_signal_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeLicenseSignalPolicy.evaluate', () {
    test('accepts a realistic English Trade License OCR read', () {
      const text = '''
        Government of Dubai
        Department of Economic Development
        Trade License
        License Number: 123456
        Trade Name: Sanad Home Services L.L.C
        Legal Form: Limited Liability Company
        Establishment Date: 01/01/2020
      ''';
      expect(TradeLicenseSignalPolicy.evaluate(text), isTrue);
    });

    test('accepts a realistic Arabic Trade License OCR read', () {
      const text = '''
        حكومة دبي
        دائرة التنمية الاقتصادية
        الرخصة التجارية
        رقم الرخصة 123456
        الاسم التجاري: سند لخدمات المنازل ذ.م.م
      ''';
      expect(TradeLicenseSignalPolicy.evaluate(text), isTrue);
    });

    test('accepts a bilingual Trade License OCR read', () {
      const text = '''
        Trade License / الرخصة التجارية
        License No: 987654
        Establishment: Sanad Trading
        المنشأة: سند للتجارة
      ''';
      expect(TradeLicenseSignalPolicy.evaluate(text), isTrue);
    });

    test('rejects Emirates ID OCR text', () {
      const text = '''
        United Arab Emirates
        Identity Card
        ID Number: 784-1990-1234567-1
        Name: John Doe
        Nationality: UAE
        Date of Birth: 01/01/1990
        Expiry Date: 01/01/2030
      ''';
      expect(TradeLicenseSignalPolicy.evaluate(text), isFalse);
    });

    test('rejects generic photo/noise OCR text', () {
      const text = 'lorem ipsum some random unrelated text from a photo';
      expect(TradeLicenseSignalPolicy.evaluate(text), isFalse);
    });

    test('rejects blank/near-empty OCR output', () {
      expect(TradeLicenseSignalPolicy.evaluate(''), isFalse);
      expect(TradeLicenseSignalPolicy.evaluate('   '), isFalse);
      expect(TradeLicenseSignalPolicy.evaluate('a b'), isFalse);
    });

    test(
      'a single generic word ("License") alone is never enough to accept',
      () {
        const text = 'This document mentions a License somewhere in it, '
            'but nothing else about it relates to any business or company.';
        expect(TradeLicenseSignalPolicy.evaluate(text), isFalse);
      },
    );

    test(
      'a strong term with only one business term (no license number) is '
      'not enough — requires a second independent signal',
      () {
        const text = 'Trade License issued for a company operating here';
        expect(TradeLicenseSignalPolicy.evaluate(text), isFalse);
      },
    );

    test(
      'a strong term plus a license-number-like pattern accepts without '
      'needing two business terms',
      () {
        const text = 'Trade License Number: 445566';
        expect(TradeLicenseSignalPolicy.evaluate(text), isTrue);
      },
    );

    test(
      'a strong term plus two independent business terms accepts without '
      'a license-number pattern',
      () {
        const text =
            'Trade License — Establishment: Sanad — Legal Form: LLC';
        expect(TradeLicenseSignalPolicy.evaluate(text), isTrue);
      },
    );

    test('is tolerant of Arabic diacritics around a strong term', () {
      // Built programmatically (base string + injected \uXXXX diacritic
      // escapes) rather than hand-typed, so the base letters are guaranteed
      // to match the policy's own literals and only the diacritic
      // stripping is under test.
      const base = 'الرخصة التجارية رقم الرخصة 112233';
      const fatha = 'َ';
      final withDiacritics = base.split('').join(fatha);
      expect(TradeLicenseSignalPolicy.evaluate(withDiacritics), isTrue);
    });

    test('is case-insensitive for English terms', () {
      const text = 'TRADE LICENSE NUMBER: 998877';
      expect(TradeLicenseSignalPolicy.evaluate(text), isTrue);
    });
  });
}
