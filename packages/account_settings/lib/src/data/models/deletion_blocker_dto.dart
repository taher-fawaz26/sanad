import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';

/// `DeletionBlockerDto`.
class DeletionBlockerDto {
  const DeletionBlockerDto({
    required this.code,
    required this.message,
    this.details,
  });

  factory DeletionBlockerDto.fromJson(Map<String, dynamic> json) =>
      DeletionBlockerDto(
        code: json['code'] as String? ?? '',
        message: json['message'] as String? ?? '',
        details: json['details'] as Map<String, dynamic>?,
      );

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  DeletionBlocker toEntity() => DeletionBlocker(
    code: DeletionBlockerCode.fromApi(code),
    rawCode: code,
    message: message,
    details: details,
  );
}
