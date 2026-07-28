import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/data/registration_simulation_service.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';

/// Holds all cross-step registration data and drives the (simulated) async
/// steps (OTP verification, document extraction).
///
/// A fresh instance is created per `ShellRoute` entry in `RegistrationModule`,
/// so leaving the flow disposes the state automatically.
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit({RegistrationSimulationService? service})
      : _service = service ?? RegistrationSimulationService(),
        super(const RegistrationState());

  final RegistrationSimulationService _service;

  // ── Plain data setters ─────────────────────────────────────────────────────

  void setEmail(String email) => emit(state.copyWith(email: email));

  void setAccountType(RegistrationAccountType type) =>
      emit(state.copyWith(accountType: type));

  void setOrganizationDetails({
    required String businessName,
    required String representativeName,
  }) =>
      emit(
        state.copyWith(
          businessName: businessName,
          representativeName: representativeName,
        ),
      );

  void setFullName(String fullName) =>
      emit(state.copyWith(fullName: fullName));

  void setEmiratesIdFront(PickedAsset asset) =>
      emit(state.copyWith(emiratesIdFront: asset));

  void setEmiratesIdBack(PickedAsset asset) =>
      emit(state.copyWith(emiratesIdBack: asset));

  void setTradeLicence(PickedAsset asset) =>
      emit(state.copyWith(tradeLicence: asset));

  // ── Simulated async steps ──────────────────────────────────────────────

  /// Verifies the OTP. Returns `true` on success. Emits [OtpStatus.verifying]
  /// while in flight and [OtpStatus.error] on failure.
  Future<bool> verifyOtp(String code) async {
    emit(state.copyWith(otpStatus: OtpStatus.verifying));
    try {
      await _service.verifyOtp(code);
      emit(state.copyWith(otpStatus: OtpStatus.idle));
      return true;
    } on Object {
      emit(state.copyWith(otpStatus: OtpStatus.error));
      return false;
    }
  }

  Future<void> resendOtp() => _service.resendOtp(state.email);

  /// Runs the (simulated) document extraction, storing the result on the state.
  ///
  /// [scenario] forces an outcome; when `null` the service rolls a realistic
  /// mix of success / error results.
  Future<void> extractDocuments({ExtractionScenario? scenario}) async {
    emit(state.copyWith(extractionStatus: ExtractionStatus.extracting));
    final result = await _service.extractDocuments(
      includeTradeLicence: state.isOrganization,
      scenario: scenario,
    );
    emit(
      state.copyWith(
        extraction: result,
        extractionStatus: ExtractionStatus.done,
      ),
    );
  }
}
