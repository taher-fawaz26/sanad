import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// SANAD green/gold orb played while AI document extraction is in progress.
///
/// Decorative only — the loading text carries the semantic state, so this
/// is excluded from the accessibility tree. Purely presentational: it knows
/// nothing about extraction, HTTP, or bloc state, and should be dropped in
/// wherever an "extracting…" visual is needed.
///
/// Renders through [AppLottie.documentExtraction], kept alive by the normal
/// widget tree, so it is never recreated (and never restarts) by unrelated
/// rebuilds of its parent, e.g. a `BlocBuilder` re-evaluating on state that
/// isn't the extraction phase.
class AppDocumentExtractionLoader extends StatelessWidget {
  const AppDocumentExtractionLoader({this.size = 300, super.key});

  /// Side length of the square animation viewport, pre-[responsiveDimension]
  /// scaling.
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppLottie.documentExtraction(size: responsiveDimension(size));
  }
}
