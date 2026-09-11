import 'package:flutter/widgets.dart';
// `show Bidi`: intl exports a `TextDirection` of its own, which would shadow
// Flutter's.
import 'package:intl/intl.dart' show Bidi;

/// The direction a piece of *content* should be laid out in, regardless of the
/// app's own language.
///
/// This is the behaviour a browser gives `dir="auto"`. It exists because
/// content in this app is not necessarily in the user's language: an Arabic UI
/// can hold an English conversation, and an English UI an Arabic one.
/// Inheriting the page's direction for such a paragraph is what produced
/// A-02 — an English assistant reply under the Arabic locale rendered
/// right-to-left, with sentence-final periods on the wrong end, `1.` list
/// markers reading `.1`, and bullets pinned to the right of their text.
///
/// Not `String.ltrIsolated`: that is for an inherently-LTR *value* embedded in
/// surrounding text — a phone number, a URL, a time. These are whole
/// paragraphs on their own lines, where the right treatment is a paragraph
/// direction rather than an isolate. The two are complements, not
/// alternatives.
TextDirection autoTextDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

/// Lays [child] out in the direction [text] itself reads in.
///
/// A widget rather than a bare [Directionality] at each call site so the
/// intent — "this subtree follows the content, not the app" — is named once
/// and the detection cannot drift between callers.
class AutoDirection extends StatelessWidget {
  /// Wraps [child] in the direction detected from [text].
  const AutoDirection({required this.text, required this.child, super.key});

  /// The content whose direction decides the layout.
  final String text;

  /// The subtree to lay out.
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: autoTextDirection(text),
    child: child,
  );
}
