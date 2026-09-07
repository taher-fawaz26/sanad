import 'package:equatable/equatable.dart';

/// Why recognition could not run, or stopped early.
///
/// A closed set of *product* reasons. The platform's own error strings —
/// `error_no_match`, `error_speech_timeout` and friends — are mapped to these
/// in the adapter and never reach the bloc, so no raw platform exception or
/// vendor string can end up on screen.
enum AiSpeechFailure {
  /// The user refused this time.
  permissionDenied,

  /// The user refused and the OS will not ask again.
  permissionPermanentlyDenied,

  /// No recognizer on this device, or none for the requested language.
  unavailable,

  /// The recognizer heard something but could not turn it into words.
  noMatch,

  /// A recognizer that needs the network could not reach it.
  network,

  /// Nobody spoke.
  timeout,

  /// Anything else the platform reported.
  platform,
}

/// One reading from the recognizer.
///
/// Partial and final results travel on the same stream and differ only by
/// [isFinal]. Keeping them together is what lets the composer show a sentence
/// forming and then settle on it without two subscriptions and two orderings
/// to reconcile.
final class AiSpeechTranscript extends Equatable {
  /// Creates a transcript.
  const AiSpeechTranscript({
    required this.text,
    required this.isFinal,
    this.confidence = 0,
  });

  /// What has been recognised so far, or finally.
  final String text;

  /// Whether the recognizer considers this its answer.
  final bool isFinal;

  /// The recognizer's own 0..1 confidence, where it reports one.
  final double confidence;

  /// Nothing recognised — the value before the first result arrives, and the
  /// value a cancelled session resets to.
  static const AiSpeechTranscript empty = AiSpeechTranscript(
    text: '',
    isFinal: false,
  );

  @override
  List<Object?> get props => [text, isFinal, confidence];
}

/// Turns speech into text with the device's own recognizer.
///
/// The implementation is the only thing in the feature that knows
/// `speech_to_text` exists, which is why the composer's whole dictation state
/// machine is testable with no microphone and no plugin.
///
/// ## Not a recorder
///
/// This produces **text**. It writes no file, creates no attachment, and holds
/// no audio session — see the adapter for why the audio session is deliberately
/// left alone here.
abstract interface class AiSpeechRecognizer {
  /// Partial and final results, in arrival order.
  Stream<AiSpeechTranscript> get transcripts;

  /// Product-level reasons recognition could not continue.
  Stream<AiSpeechFailure> get failures;

  /// Whether the recognizer currently holds the microphone.
  ///
  /// Driven by the platform, not by us: a recognizer built for short phrases
  /// will stop on its own after a pause, and the composer has to follow that
  /// rather than claim to still be listening.
  Stream<bool> get listening;

  /// Brings the recognizer up. Returns whether it can be used at all.
  ///
  /// Safe to call more than once; the platform plugin is a singleton and only
  /// initialises once.
  Future<bool> initialize();

  /// Locale identifiers the device can recognise, as BCP-47-ish tags.
  ///
  /// Empty when the recognizer is unavailable — the caller must treat that as
  /// "no preference" rather than as an error.
  Future<List<String>> availableLocales();

  /// Starts listening.
  ///
  /// [localeId] is a tag from [availableLocales]; `null` means "let the device
  /// choose", which is the graceful path when the app's language has no
  /// recognizer installed.
  Future<void> start({String? localeId});

  /// Stops listening and asks for a final result.
  Future<void> stop();

  /// Stops listening and throws away whatever was heard.
  Future<void> cancel();

  /// Releases subscriptions. Safe while listening, and safe to call twice.
  Future<void> dispose();
}
