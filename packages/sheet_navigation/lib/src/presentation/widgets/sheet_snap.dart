/// Snap-extent helpers shared by `ModalSheetRoute` and `SheetDragController`.
abstract final class SheetSnap {
  SheetSnap._();

  /// Returns the entry of [fractions] nearest to [extent].
  static double nearest(List<double> fractions, double extent) {
    assert(fractions.isNotEmpty, 'fractions must not be empty');
    return fractions.reduce(
      (a, b) => (extent - a).abs() <= (extent - b).abs() ? a : b,
    );
  }
}
