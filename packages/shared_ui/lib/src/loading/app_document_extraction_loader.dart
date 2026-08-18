import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

/// SANAD green/gold orb played while AI document extraction is in progress.
///
/// Decorative only — the loading text carries the semantic state, so this
/// is excluded from the accessibility tree. Purely presentational: it knows
/// nothing about extraction, HTTP, or bloc state, and should be dropped in
/// wherever an "extracting…" visual is needed.
///
/// Renders through a single `Lottie.asset` element kept alive by the normal
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
    final dimension = responsiveDimension(size);
    return Semantics(
      excludeSemantics: true,
      child: RepaintBoundary(
        child: Lottie.asset(
          AppAnimations.documentExtractionLoader,
          package: AppAssets.package,
          width: dimension,
          height: dimension,
          fit: BoxFit.contain,
          repeat: true,
        ),
      ),
    );
  }
}
