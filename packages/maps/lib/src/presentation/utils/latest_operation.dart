/// Tracks the most-recently-started asynchronous operation so results from
/// superseded operations can be discarded — the "latest request wins" rule.
///
/// Replaces the hand-rolled `int _opId` counters that were duplicated across
/// the map blocs. Each call site calls [begin] before awaiting and checks
/// [isCurrent] after, ignoring the result when a newer operation has started.
class LatestOperation {
  int _current = 0;

  /// Marks the start of a new operation and returns its token.
  int begin() => ++_current;

  /// Whether [token] still identifies the most recently started operation.
  bool isCurrent(int token) => token == _current;
}
