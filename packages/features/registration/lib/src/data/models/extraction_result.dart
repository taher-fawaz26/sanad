import 'package:equatable/equatable.dart';

/// A single labelled field extracted from a document (label → value).
///
/// Kept as an explicit key/value pair so the review screen can render rows
/// generically without hard-coding every field name in the widget tree.
class ExtractedField extends Equatable {
  const ExtractedField(
    this.label,
    this.value, {
    this.highlight = false,
    this.fullWidth = false,
    this.rtl = false,
  });

  final String label;

  /// The extracted value. Empty renders as an em-dash placeholder on screen.
  final String value;

  /// When true the value is emphasised (e.g. an expiry date on the error card).
  final bool highlight;

  /// When true the field spans the full card width; otherwise it shares a row
  /// with the next half-width field (two-column grid).
  final bool fullWidth;

  /// When true the value is rendered right-to-left (Arabic name / trade name).
  final bool rtl;

  @override
  List<Object?> get props => [label, value, highlight, fullWidth, rtl];
}

/// Why a document could not be verified. [none] means it extracted cleanly.
enum DocumentIssue {
  none,

  /// The photo was too blurry / cropped to read reliably (Figma "Image Unclear").
  imageUnclear,

  /// The Emirates ID is already linked to another account (HTTP 409).
  alreadyRegistered,

  /// The trade licence is past its expiry date (Figma "Expired").
  expiredLicence,
}

/// Extracted Emirates ID data plus its verification outcome.
class EmiratesIdResult extends Equatable {
  const EmiratesIdResult({
    required this.fullNameEn,
    required this.fullNameAr,
    required this.idNumber,
    required this.nationality,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.gender,
    this.issue = DocumentIssue.none,
  });

  /// A clean, successfully-extracted sample (used by the simulation service).
  const EmiratesIdResult.sample()
      : this(
          fullNameEn: 'Mohammed Ahmed Al Ali',
          fullNameAr: 'محمد أحمد العلي',
          idNumber: '784-1990-1234567-1',
          nationality: 'UAE',
          dateOfBirth: '15/03/1990',
          expiryDate: '25/12/2027',
          gender: 'Male',
        );

  /// An unreadable result — all fields blank, flagged as an unclear image.
  const EmiratesIdResult.unclear()
      : this(
          fullNameEn: '',
          fullNameAr: '',
          idNumber: '',
          nationality: '',
          dateOfBirth: '',
          expiryDate: '',
          gender: '',
          issue: DocumentIssue.imageUnclear,
        );

  /// The Emirates ID belongs to an account that already exists (HTTP 409).
  const EmiratesIdResult.alreadyRegistered()
      : this(
          fullNameEn: '',
          fullNameAr: '',
          idNumber: '',
          nationality: '',
          dateOfBirth: '',
          expiryDate: '',
          gender: '',
          issue: DocumentIssue.alreadyRegistered,
        );

  final String fullNameEn;
  final String fullNameAr;
  final String idNumber;
  final String nationality;
  final String dateOfBirth;
  final String expiryDate;
  final String gender;
  final DocumentIssue issue;

  bool get ok => issue == DocumentIssue.none;

  @override
  List<Object?> get props => [
        fullNameEn,
        fullNameAr,
        idNumber,
        nationality,
        dateOfBirth,
        expiryDate,
        gender,
        issue,
      ];
}

/// Extracted trade-licence data plus its verification outcome.
class TradeLicenceResult extends Equatable {
  const TradeLicenceResult({
    required this.tradeNameEn,
    required this.tradeNameAr,
    required this.licenceNo,
    required this.licenceType,
    required this.establishmentDate,
    required this.issuanceDate,
    required this.legalForm,
    required this.unifiedRegNo,
    required this.unifiedLicenceNo,
    this.issue = DocumentIssue.none,
  });

  const TradeLicenceResult.sample()
      : this(
          tradeNameEn: 'Al Noor Digital Solutions LLC',
          tradeNameAr: 'شركة النور للحلول الرقمية ذ.م.م',
          licenceNo: 'CN-9837201',
          licenceType: 'Trade',
          establishmentDate: '15/03/2018',
          issuanceDate: '10/06/2025',
          legalForm: 'LLC (ذ.م.م)',
          unifiedRegNo: 'URN-2024-084523',
          unifiedLicenceNo: 'UL-DXB-00347891',
        );

  const TradeLicenceResult.expired()
      : this(
          tradeNameEn: '',
          tradeNameAr: '',
          licenceNo: '',
          licenceType: '',
          establishmentDate: '',
          issuanceDate: '',
          legalForm: '',
          unifiedRegNo: '',
          unifiedLicenceNo: '',
          issue: DocumentIssue.expiredLicence,
        );

  final String tradeNameEn;
  final String tradeNameAr;
  final String licenceNo;
  final String licenceType;
  final String establishmentDate;
  final String issuanceDate;
  final String legalForm;
  final String unifiedRegNo;
  final String unifiedLicenceNo;
  final DocumentIssue issue;

  bool get ok => issue == DocumentIssue.none;

  @override
  List<Object?> get props => [
        tradeNameEn,
        tradeNameAr,
        licenceNo,
        licenceType,
        establishmentDate,
        issuanceDate,
        legalForm,
        unifiedRegNo,
        unifiedLicenceNo,
        issue,
      ];
}

/// The combined outcome of the "AI extraction" step.
///
/// [tradeLicence] is `null` for the individual path (no trade licence).
class ExtractionResult extends Equatable {
  const ExtractionResult({required this.emiratesId, this.tradeLicence});

  final EmiratesIdResult emiratesId;
  final TradeLicenceResult? tradeLicence;

  /// True when every included document extracted without an issue.
  bool get allOk =>
      emiratesId.ok && (tradeLicence == null || tradeLicence!.ok);

  @override
  List<Object?> get props => [emiratesId, tradeLicence];
}

/// Forces a particular extraction outcome. Real extraction is
/// non-deterministic, so this lets tests / QA reach the error screens.
enum ExtractionScenario { success, imageUnclear, expiredLicence }
