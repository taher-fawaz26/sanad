/// Unicode bidi isolate control characters.
///
/// U+2066 LEFT-TO-RIGHT ISOLATE opens a run whose base direction is forced to
/// left-to-right; U+2069 POP DIRECTIONAL ISOLATE closes it. Unlike the older
/// LRE/PDF embedding marks, an *isolate* also prevents the wrapped run from
/// affecting the bidi resolution of the surrounding text — so a phone number
/// dropped into an Arabic sentence can't reorder the words around it.
const String _lri = '\u{2066}';
const String _pdi = '\u{2069}';

/// LTR-direction helpers for inherently left-to-right values.
///
/// Phone numbers, email addresses, URLs and handles must always read
/// left-to-right — including a leading `+`, which is a bidi-neutral character
/// that otherwise "sticks" to the end of the number under an RTL (Arabic)
/// paragraph (rendering `971…+` instead of `+971…`).
///
/// Wrap such a value in [ltrIsolated] before putting it in a `Text` /
/// `TextSpan`, **or** — for a whole read-only field — prefer the design-system
/// components that expose an `isLtr` flag (`AppTextField`, `AppPhoneField`,
/// `AppKeyValueCard`, `AppGroupedKeyValueList`), which apply this for you.
///
/// This is the single, app-wide fix for the recurring "`+` at the wrong end"
/// bug (SAN-770 / SAN-771 / SAN-775). Reach for it instead of a bare
/// `TextDirection.ltr`, which forces the direction but does not isolate the
/// value from neighbouring text.
extension LtrIsolate on String {
  /// This string wrapped in a Unicode LTR isolate (U+2066 … U+2069) so it
  /// renders left-to-right regardless of the ambient paragraph direction,
  /// without disturbing the bidi resolution of adjacent text.
  ///
  /// Safe on any value: on an already-LTR string it is visually a no-op.
  String get ltrIsolated => '$_lri$this$_pdi';
}
