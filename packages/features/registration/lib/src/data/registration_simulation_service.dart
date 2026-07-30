import 'dart:math';

import 'package:registration/src/data/models/extraction_result.dart';

/// Stand-in for the (not-yet-existing) backend calls the sign-up flow needs.
///
/// The Figma flow implies three server capabilities that the repo has no
/// endpoint for yet: OTP verification, "AI" document extraction (OCR), and
/// final account creation. Until those contracts exist this service simulates
/// them with realistic delays and mock data so the UI/UX can be built and
/// exercised end-to-end.
///
/// Every method is a clearly-marked `TODO(registration)` seam: swap the body
/// for a real API/repository call without changing any call site.
class RegistrationSimulationService {
  RegistrationSimulationService({Random? random})
      : _random = random ?? Random();

  final Random _random;

  /// Simulates the "AI Extracting document information" step.
  ///
  /// [includeTradeLicence] is `true` for the organization path only.
  /// [scenario] forces the outcome; when `null` a realistic outcome is rolled
  /// (mostly success, occasionally an unclear image or expired licence) so the
  /// error screens are reachable in the running app and recover on re-upload.
  Future<ExtractionResult> extractDocuments({
    required bool includeTradeLicence,
    ExtractionScenario? scenario,
  }) async {
    // TODO(registration): replace with the real OCR / document-extraction API.
    await Future<void>.delayed(const Duration(milliseconds: 2600));

    final effective = scenario ?? _rollScenario(includeTradeLicence);

    final emiratesId = switch (effective) {
      ExtractionScenario.imageUnclear => const EmiratesIdResult.unclear(),
      _ => const EmiratesIdResult.sample(),
    };

    if (!includeTradeLicence) {
      return ExtractionResult(emiratesId: emiratesId);
    }

    final tradeLicence = switch (effective) {
      ExtractionScenario.expiredLicence => const TradeLicenceResult.expired(),
      _ => const TradeLicenceResult.sample(),
    };

    return ExtractionResult(
      emiratesId: emiratesId,
      tradeLicence: tradeLicence,
    );
  }

  /// Weighted random outcome: ~70% success, ~18% unclear ID, and (organization
  /// only) ~12% expired licence.
  ExtractionScenario _rollScenario(bool includeTradeLicence) {
    final roll = _random.nextDouble();
    if (roll < 0.18) return ExtractionScenario.imageUnclear;
    if (includeTradeLicence && roll < 0.30) {
      return ExtractionScenario.expiredLicence;
    }
    return ExtractionScenario.success;
  }

  /// Simulates creating the account once every step is complete.
  Future<void> completeRegistration() async {
    // TODO(registration): call auth/register (or the passwordless sign-up
    // endpoint once it exists) and surface failures to the caller.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
