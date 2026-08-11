import 'package:auth/src/domain/entities/resend_info_entity.dart';

/// Data model for [ResendInfo] — inherits fields, adds JSON I/O.
class ResendInfoModel extends ResendInfo {
  const ResendInfoModel({
    required super.canResend,
    required super.remainingSeconds,
    required super.attemptsLeft,
  });

  factory ResendInfoModel.fromJson(Map<String, dynamic> json) =>
      ResendInfoModel(
        canResend: json['canResend'] as bool,
        remainingSeconds: (json['remainingSeconds'] as num).toInt(),
        attemptsLeft: (json['attemptsLeft'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'canResend': canResend,
    'remainingSeconds': remainingSeconds,
    'attemptsLeft': attemptsLeft,
  };
}
