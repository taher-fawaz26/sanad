/// Reads from and writes to the system clipboard.
abstract class ClipboardService {
  /// Copies [text] to the clipboard.
  Future<void> copy(String text);

  /// Returns the current plain-text clipboard contents, or `null` if empty.
  Future<String?> paste();

  /// Clears the clipboard.
  Future<void> clear();

  /// Whether the clipboard currently holds plain-text data.
  Future<bool> hasData();
}
