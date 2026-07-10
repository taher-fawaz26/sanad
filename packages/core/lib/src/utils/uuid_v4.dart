import 'dart:math';

/// Generates a random RFC 4122 v4 UUID.
String generateUuidV4() {
  final b = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  const hex = '0123456789abcdef';
  String h(int i) => '${hex[b[i] >> 4]}${hex[b[i] & 0x0f]}';
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

bool isCanonicalUuid(String value) => RegExp(
  '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value.trim());

String servingAreaIdForProfileSetup(String? raw) {
  final t = raw?.trim();
  if (t != null && t.isNotEmpty && isCanonicalUuid(t)) return t;
  return generateUuidV4();
}
