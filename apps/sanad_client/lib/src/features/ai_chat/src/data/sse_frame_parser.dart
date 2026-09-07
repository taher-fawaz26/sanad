/// Incremental parser for the `text/event-stream` framing.
///
/// Feed it decoded text chunks in arrival order; it hands back the payload of
/// every frame those chunks completed. It holds only the trailing partial line
/// between calls, so no input is ever re-scanned.
///
/// Total, like the rest of this feature: nothing here throws. A comment line,
/// an unknown field, a frame with no `data` and a truncated tail are all
/// handled by dropping them, never by failing.
///
/// ## Scope
///
/// This class knows about `data:`/`event:`/`id:`/`retry:` lines and blank-line
/// frame boundaries. It knows nothing about JSON, the SANAD protocol, or what
/// a frame means — `AiChatEventCodec` owns that, and the transport hands each
/// returned payload straight to it.
///
/// ## Line endings
///
/// The observed server uses bare LF, but the spec allows `\n`, `\r\n` and a
/// lone `\r`. All three are handled, including a `\r\n` pair split across two
/// chunks (see [_skipLf]).
class SseFrameParser {
  static const int _cr = 13;
  static const int _lf = 10;

  /// The current line, accumulated across chunk boundaries.
  final StringBuffer _line = StringBuffer();

  /// The `data` values of the frame being assembled.
  final StringBuffer _data = StringBuffer();

  /// Whether the current frame has seen at least one `data:` line. A frame
  /// without one dispatches nothing, so this is not the same as `_data`
  /// being non-empty — `data:` with an empty value is still a data line.
  bool _sawData = false;

  /// Set when the last consumed character was CR. If the next character is LF
  /// it belongs to that CR and is skipped rather than ending a second, empty
  /// line. Survives a chunk boundary, which is the whole reason it is a field.
  bool _skipLf = false;

  /// Whether a frame is still being assembled — i.e. the stream ended without
  /// a final blank line.
  bool get hasIncompleteFrame => _sawData || _line.isNotEmpty;

  /// How many characters of the incomplete frame were buffered.
  ///
  /// A count, not the content: it is only ever used for a diagnostic, and a
  /// diagnostic must never carry AI or user prose.
  int get incompleteFrameLength => _data.length + _line.length;

  /// Consumes [chunk] and returns the payloads of every frame it completed.
  ///
  /// Returns an empty iterable — not `null` — when the chunk completed no
  /// frame, which is the common case for a chunk landing mid-frame.
  Iterable<String> addChunk(String chunk) {
    if (chunk.isEmpty) return const <String>[];

    List<String>? frames;
    var start = 0;

    for (var i = 0; i < chunk.length; i++) {
      final unit = chunk.codeUnitAt(i);
      if (unit != _lf && unit != _cr) continue;

      // The LF half of a CRLF. `i == start` is what makes this precise: it can
      // only hold for the character immediately after a terminator, and the
      // only terminator that sets [_skipLf] is CR.
      if (unit == _lf && _skipLf && i == start) {
        _skipLf = false;
        start = i + 1;
        continue;
      }

      _skipLf = unit == _cr;
      _line.write(chunk.substring(start, i));
      start = i + 1;

      final frame = _endLine();
      if (frame != null) (frames ??= <String>[]).add(frame);
    }

    // Whatever follows the last terminator is a partial line; keep it for the
    // next chunk.
    if (start < chunk.length) _line.write(chunk.substring(start));

    return frames ?? const <String>[];
  }

  /// Completes the current line. Returns the frame payload if that line was
  /// the blank line closing a frame that had data, and `null` otherwise.
  String? _endLine() {
    final line = _line.toString();
    _line.clear();

    if (line.isEmpty) {
      // Blank line: the frame ends here. A frame with no `data:` line
      // dispatches nothing, per the spec.
      if (!_sawData) return null;
      final data = _data.toString();
      _data.clear();
      _sawData = false;
      return data;
    }

    // A line starting with a colon is a comment. Servers use these as
    // keepalives; this one sends none, but ignoring them costs nothing.
    if (line.startsWith(':')) return null;

    final colon = line.indexOf(':');
    final String field;
    final String value;
    if (colon < 0) {
      // A field name with no colon: value is the empty string.
      field = line;
      value = '';
    } else {
      field = line.substring(0, colon);
      // Exactly one optional leading space is stripped, not all whitespace.
      value = line.startsWith(' ', colon + 1)
          ? line.substring(colon + 2)
          : line.substring(colon + 1);
    }

    if (field == 'data') {
      // Multiple `data:` lines in one frame join with a newline.
      if (_sawData) _data.write('\n');
      _data.write(value);
      _sawData = true;
    }

    // `event`, `id`, `retry` and anything unrecognised are accepted and
    // ignored. This server sends none of them; tolerating them keeps us
    // spec-correct if it starts.
    return null;
  }
}
