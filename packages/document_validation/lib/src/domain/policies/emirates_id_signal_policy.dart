/// Deterministic, multi-signal Emirates ID classifier applied to raw
/// recognized text — **not** a legal-validity or identity-matching check.
///
/// Answers exactly one question: *"does this look like a UAE Emirates ID
/// card?"* It never attempts expiry, authenticity, ownership, or identity
/// verification — those remain the backend's job after upload.
///
/// Text recognition here runs with `TextRecognitionScript.latin` (see
/// `EmiratesIdScannerDataSource`), so signals are drawn from the Latin-script
/// wording, the ID-number pattern, and the machine-readable zone (MRZ) that
/// an Emirates ID carries.
///
/// The card is captured as **two separate sides** (front and back slots), and
/// the two sides carry very different Latin text, so [evaluate] accepts
/// either side's signature:
///
/// * **Front** — federal-authority wording ("United Arab Emirates",
///   "Identity Card") and the `784-YYYY-NNNNNNN-C` ID number.
/// * **Back** — the MRZ (`ILARE…<<<` filler runs) plus card-layout fields
///   ("Card Number", "Occupation", "Employer", "Issuing Place"). The MRZ's
///   `<<` filler sequence is unique to machine-readable travel/ID documents
///   and does not appear on unrelated photos or a Trade License.
///
/// As with the Trade License policy, a single generic word must never decide
/// the outcome: each side requires at least one *strong* signal **and**, for
/// the weaker strong-signals, independent corroboration before accepting.
abstract final class EmiratesIdSignalPolicy {
  EmiratesIdSignalPolicy._();

  /// The Emirates ID number format: `784-YYYY-NNNNNNN-C` (15 digits total).
  /// This alone is a near-unique, strong signal — no other UAE document
  /// uses this exact pattern.
  static final RegExp _idNumberPattern = RegExp(
    r'784[\s-]?\d{4}[\s-]?\d{7}[\s-]?\d',
  );

  /// Machine-readable-zone signatures found on the **back** of the card:
  /// the `ILARE`/`IDARE` document/country prefix, and the `<<` filler runs
  /// (`<` is often misread by OCR, so a couple of tolerant forms are
  /// included). Unique to MRZ documents — never on a random photo or a
  /// Trade License.
  static final List<RegExp> _mrzPatterns = [
    RegExp('i[dl]are'),
    RegExp('<<'),
    RegExp('are[<kc]{2,}'),
  ];

  /// Back-of-card layout fields, used to corroborate a partially-read MRZ.
  static const _backTerms = [
    'card number',
    'occupation',
    'employer',
    'issuing place',
    'sponsor',
    'signature',
  ];

  /// Strong, federal-authority / card-identity phrases.
  static const _strongTerms = [
    'united arab emirates',
    'identity card',
    'resident identity',
    'federal authority for identity',
  ];

  /// Secondary card-layout terms — a single hit is not enough on its own
  /// (see class doc); at least two are required when the ID-number pattern
  /// is absent.
  static const _secondaryTerms = [
    'id number',
    'name',
    'nationality',
    'date of birth',
    'expiry date',
    'issuing date',
    'sex',
    'signature',
    'occupation',
    'employer',
  ];

  /// Minimum recognized-text length below which the read is treated as too
  /// sparse to classify confidently, rather than a confident rejection.
  static const _kMinTextLength = 8;

  /// Whether [rawRecognizedText] looks like an Emirates ID card (front **or**
  /// back side).
  static bool evaluate(String rawRecognizedText) {
    final text = _normalize(rawRecognizedText);
    if (text.length < _kMinTextLength) return false;
    return _looksLikeFront(text) || _looksLikeBack(text);
  }

  /// Front-side signature: federal-authority wording and the 784 ID number.
  static bool _looksLikeFront(String text) {
    final hasIdNumber = _idNumberPattern.hasMatch(text);
    final hasStrongTerm = _strongTerms.any(text.contains);

    if (hasIdNumber && hasStrongTerm) return true;
    if (hasIdNumber || hasStrongTerm) {
      // One strong signal alone still needs independent corroboration —
      // guards against a stray ID-number-shaped digit run, or the phrase
      // "United Arab Emirates" appearing on an unrelated UAE document.
      final secondaryHits = _secondaryTerms.where(text.contains).length;
      return secondaryHits >= 2;
    }
    return false;
  }

  /// Back-side signature: the MRZ (strong, near-unique) on its own, or a
  /// partially-read MRZ corroborated by the back-of-card fields.
  static bool _looksLikeBack(String text) {
    final hasMrz = _mrzPatterns.any((p) => p.hasMatch(text));
    if (!hasMrz) {
      // No MRZ at all → require two independent back-of-card fields so a
      // stray "signature"/"name" line never carries the decision alone.
      return _backTerms.where(text.contains).length >= 2;
    }
    // A clear `<<` filler run is unique enough to accept on its own; the
    // weaker `ILARE`/`ARE<<` forms still get corroboration from a card field.
    if (text.contains('<<')) return true;
    return _backTerms.any(text.contains);
  }

  static String _normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
