import 'package:document_validation/src/domain/policies/emirates_id_signal_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmiratesIdSignalPolicy.evaluate', () {
    test('accepts a realistic Emirates ID front-side OCR read', () {
      const text = '''
        United Arab Emirates
        Federal Authority For Identity, Citizenship, Customs & Port Security
        Resident Identity Card
        ID Number: 784-1990-1234567-1
        Name: John Doe
        Nationality: GBR
        Date of Birth: 01/01/1990
        Expiry Date: 01/01/2030
      ''';
      expect(EmiratesIdSignalPolicy.evaluate(text), isTrue);
    });

    test('accepts on ID number pattern plus two secondary signals alone', () {
      const text = 'ID Number 784199012345671 Name John Nationality GBR';
      expect(EmiratesIdSignalPolicy.evaluate(text), isTrue);
    });

    test('accepts on a strong term plus two secondary signals alone', () {
      const text = 'United Arab Emirates — Name: John — Sex: M';
      expect(EmiratesIdSignalPolicy.evaluate(text), isTrue);
    });

    test('accepts a realistic Emirates ID BACK-side OCR read (MRZ)', () {
      // The back has no "United Arab Emirates"/784 number; its signature is
      // the MRZ filler runs plus card-layout fields.
      const text = '''
        Card Number: 123456789
        Occupation: Engineer
        Employer: Sanad LLC
        Issuing Place: Dubai
        ILARE1234567890<<<<<<<<<<<<
        8501012M3001019ARE<<<<<<<<<<8
        DOE<<JOHN<<<<<<<<<<<<<<<<<<<<
      ''';
      expect(EmiratesIdSignalPolicy.evaluate(text), isTrue);
    });

    test('accepts the back side on a clear MRZ filler run alone', () {
      const text = 'IDARE7845201234<<<< some smudged card text';
      expect(EmiratesIdSignalPolicy.evaluate(text), isTrue);
    });

    test(
      'a single back-of-card field alone (no MRZ) is not enough',
      () {
        const text = 'A form with an Occupation line and little else here';
        expect(EmiratesIdSignalPolicy.evaluate(text), isFalse);
      },
    );

    test('rejects Trade License OCR text', () {
      const text = '''
        Government of Dubai
        Department of Economic Development
        Trade License
        License Number: 123456
        Trade Name: Sanad Home Services L.L.C
        Legal Form: Limited Liability Company
      ''';
      expect(EmiratesIdSignalPolicy.evaluate(text), isFalse);
    });

    test('rejects generic photo/noise OCR text', () {
      const text = 'lorem ipsum some random unrelated text from a photo';
      expect(EmiratesIdSignalPolicy.evaluate(text), isFalse);
    });

    test('rejects blank/near-empty OCR output', () {
      expect(EmiratesIdSignalPolicy.evaluate(''), isFalse);
      expect(EmiratesIdSignalPolicy.evaluate('   '), isFalse);
      expect(EmiratesIdSignalPolicy.evaluate('a'), isFalse);
    });

    test(
      'a single strong term alone (no corroborating signal) is not enough',
      () {
        const text = 'This photo happens to mention United Arab Emirates '
            'once but nothing else about it looks like an ID card.';
        expect(EmiratesIdSignalPolicy.evaluate(text), isFalse);
      },
    );

    test(
      'a bare ID-number-shaped digit run alone (no corroborating signal) '
      'is not enough',
      () {
        const text =
            'Some receipt with a long reference number 784123456789012 '
            'on it';
        expect(EmiratesIdSignalPolicy.evaluate(text), isFalse);
      },
    );

    test('is case-insensitive', () {
      const text = 'UNITED ARAB EMIRATES — NAME: JOHN — SEX: M';
      expect(EmiratesIdSignalPolicy.evaluate(text), isTrue);
    });
  });
}
