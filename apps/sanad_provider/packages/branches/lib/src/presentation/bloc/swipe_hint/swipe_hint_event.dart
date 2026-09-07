part of 'swipe_hint_bloc.dart';

sealed class SwipeHintEvent extends Equatable {
  const SwipeHintEvent();

  @override
  List<Object?> get props => [];
}

final class SwipeHintLoadRequested extends SwipeHintEvent {
  const SwipeHintLoadRequested();
}

final class SwipeHintMarkedSeen extends SwipeHintEvent {
  const SwipeHintMarkedSeen();
}
