/// Standard API error response DTO.
class ApiErrorResponse {
  const ApiErrorResponse({
    required this.message,
    this.code,
    this.errors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      ApiErrorResponse(
        message:
            json['message'] as String? ??
            json['detail'] as String? ??
            'Unknown error',
        code: json['code'] as String?,
        errors: _parseFieldErrors(json['errors']),
      );

  final String message;
  final String? code;
  final Map<String, List<String>>? errors;

  static Map<String, List<String>>? _parseFieldErrors(dynamic raw) {
    if (raw is! Map) return null;
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((e) => e.toString()).toList()
            : [value.toString()],
      ),
    );
  }
}
