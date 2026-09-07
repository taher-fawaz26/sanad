part of 'swipe_hint_bloc.dart';

class SwipeHintState extends Equatable {
  const SwipeHintState({
    this.loaded = false,
    this.seen = false,
    this.attempted = false,
  });

  /// Whether the persisted flag has been read from Hive. Until then, the
  /// hint stays disarmed so it can't briefly play before we know its state.
  final bool loaded;

  /// The persisted "have we ever shown this hint" bit.
  final bool seen;

  /// Session-only latch: once the hint arms for a row, this flips to `true`
  /// so subsequent rebuilds render row 0 plainly instead of re-wrapping.
  final bool attempted;

  /// The hint arms only when the flag has been loaded, has never been seen,
  /// and hasn't yet been attempted this session.
  bool get shouldArm => loaded && !seen && !attempted;

  SwipeHintState copyWith({bool? loaded, bool? seen, bool? attempted}) =>
      SwipeHintState(
        loaded: loaded ?? this.loaded,
        seen: seen ?? this.seen,
        attempted: attempted ?? this.attempted,
      );

  @override
  List<Object?> get props => [loaded, seen, attempted];
}
