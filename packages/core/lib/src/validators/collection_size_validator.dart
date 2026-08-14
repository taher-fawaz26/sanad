/// Collection item-count validation — pure Dart, no Flutter dependency.
///
/// Takes a plain `int` count rather than a `List<T>` so callers pass
/// `items.length` without forcing a generic type parameter here.
abstract final class CollectionSizeValidator {
  CollectionSizeValidator._();

  static bool isValid(int? count, {int? minItems, int? maxItems}) {
    final c = count ?? 0;
    if (minItems != null && c < minItems) return false;
    if (maxItems != null && c > maxItems) return false;
    return true;
  }
}
