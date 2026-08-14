import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('initialsOf', () {
    test('extracts initials from a first and last name', () {
      expect(initialsOf('Ali Hassan'), equals('AH'));
    });

    test('extracts a single initial from a single-word name', () {
      expect(initialsOf('Taher'), equals('T'));
    });

    test('uses only the first two words for a longer name', () {
      expect(initialsOf('Ahmed Mohammed Al Mansouri'), equals('AM'));
    });

    test('uppercases lowercase input', () {
      expect(initialsOf('ali hassan'), equals('AH'));
    });

    test('tolerates extra whitespace between words', () {
      expect(initialsOf('Ali   Hassan'), equals('AH'));
    });

    test('trims leading/trailing whitespace', () {
      expect(initialsOf('  Ali Hassan  '), equals('AH'));
    });

    test('returns null for null, empty, or whitespace-only input', () {
      expect(initialsOf(null), isNull);
      expect(initialsOf(''), isNull);
      expect(initialsOf('   '), isNull);
    });
  });
}
