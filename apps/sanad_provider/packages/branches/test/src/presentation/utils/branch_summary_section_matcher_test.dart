import 'package:branches/src/presentation/utils/branch_summary_section_matcher.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matchFailureToSection', () {
    test(
      'matches the reported "availability" backend error to workingHours',
      () {
        const failure = ValidationFailure(
          message: 'availability must contain at least 1 elements',
          messages: ['availability must contain at least 1 elements'],
        );

        expect(
          matchFailureToSection(failure),
          BranchSummarySection.workingHours,
        );
      },
    );

    test('matches "workers" to team', () {
      const failure = ValidationFailure(
        message: 'workers must contain at least 1 elements',
        messages: ['workers must contain at least 1 elements'],
      );

      expect(matchFailureToSection(failure), BranchSummarySection.team);
    });

    test('matches "serviceIds" text to services', () {
      const failure = ValidationFailure(
        message: 'each value in serviceIds must be a string',
        messages: ['each value in serviceIds must be a string'],
      );

      expect(matchFailureToSection(failure), BranchSummarySection.services);
    });

    test(
      'matches "radiusKm" text to coverage (substring match on "radius")',
      () {
        const failure = ValidationFailure(
          message: 'radiusKm must not be less than 0.1',
          messages: ['radiusKm must not be less than 0.1'],
        );

        expect(matchFailureToSection(failure), BranchSummarySection.coverage);
      },
    );

    test('matches an explicit coverage-radius message to coverage', () {
      const failure = ValidationFailure(
        message: 'coverage radius must not be less than 0.1',
        messages: ['coverage radius must not be less than 0.1'],
      );

      expect(matchFailureToSection(failure), BranchSummarySection.coverage);
    });

    test('matches "branchPhone" text to contact', () {
      const failure = ValidationFailure(
        message: 'branch phone must be a valid phone number',
        messages: ['branch phone must be a valid phone number'],
      );

      expect(matchFailureToSection(failure), BranchSummarySection.contact);
    });

    test('matches "city" text to branchInfo', () {
      const failure = ValidationFailure(
        message: 'cityId must be a string',
        messages: ['cityId must be a string'],
      );

      expect(matchFailureToSection(failure), BranchSummarySection.branchInfo);
    });

    test('returns the first matching message when messages has several', () {
      const failure = ValidationFailure(
        message: 'multiple errors',
        messages: [
          'branchName must not be empty',
          'workers must contain at least 1 elements',
        ],
      );

      expect(matchFailureToSection(failure), BranchSummarySection.branchInfo);
    });

    test('returns null when no keyword matches — never invents a section', () {
      const failure = ServerFailure(message: 'Internal error');

      expect(matchFailureToSection(failure), isNull);
    });

    test(
      'falls back to the single localizedMessage for non-validation failures',
      () {
        const failure = ConflictFailure(
          message: 'This worker is already assigned',
        );

        expect(matchFailureToSection(failure), BranchSummarySection.team);
      },
    );
  });
}
