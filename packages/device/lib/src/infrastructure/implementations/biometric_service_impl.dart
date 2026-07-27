import 'package:device/src/domain/entities/biometric_auth_result.dart';
import 'package:device/src/domain/enums/biometric_type.dart';
import 'package:device/src/domain/services/biometric_service.dart';
import 'package:device/src/infrastructure/providers/biometric_provider.dart';

class BiometricServiceImpl implements BiometricService {
  const BiometricServiceImpl(this._provider);

  final BiometricProvider _provider;

  @override
  Future<bool> isSupported() => _provider.isSupported();

  @override
  Future<List<BiometricType>> availableBiometrics() =>
      _provider.availableBiometrics();

  @override
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) => _provider.authenticate(reason: reason, biometricOnly: biometricOnly);

  @override
  Future<void> cancel() => _provider.cancel();
}
