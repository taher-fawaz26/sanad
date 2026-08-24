import 'package:account_settings/src/domain/entities/deletion_warning.dart';
import 'package:account_settings/src/domain/enums/deletion_warning_code.dart';

/// `DeletionWarningDto`.
class DeletionWarningDto {
  const DeletionWarningDto({
    required this.code,
    required this.message,
    this.details,
  });

  factory DeletionWarningDto.fromJson(Map<String, dynamic> json) =>
      DeletionWarningDto(
        code: json['code'] as String? ?? '',
        message: json['message'] as String? ?? '',
        details: json['details'] as Map<String, dynamic>?,
      );

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  DeletionWarning toEntity() => DeletionWarning(
    code: DeletionWarningCode.fromApi(code),
    rawCode: code,
    message: message,
    details: details,
  );
}
