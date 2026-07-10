part of 'translate_bloc.dart';

sealed class TranslateEvent extends Equatable {
  const TranslateEvent();

  @override
  List<Object> get props => [];
}

class TrArabicEvent extends TranslateEvent {}

class TrEnglishEvent extends TranslateEvent {}
