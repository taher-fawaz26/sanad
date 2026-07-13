/// String utility extensions — pure Dart, no Flutter dependency.
extension StringExtensions on String {
  bool get isNullOrEmpty => trim().isEmpty;

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get trimmed => trim();

  bool get isValidEmail {
    if (trim().isEmpty) return false;
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(trim());
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}
