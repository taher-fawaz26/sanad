import 'package:flutter/services.dart';

/// Wraps Flutter's platform [Clipboard]. No plugin type escapes this class.
class ClipboardProvider {
  const ClipboardProvider();

  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  Future<void> clear() => Clipboard.setData(const ClipboardData(text: ''));

  Future<bool> hasData() => Clipboard.hasStrings();
}
