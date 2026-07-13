import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'translate_event.dart';
part 'translate_state.dart';

/// Single source of truth for app language (`ar` / `en`).
/// Hydrated — survives app restarts. Drives EasyLocalization and API headers.
class TranslateBloc extends HydratedBloc<TranslateEvent, TranslateState> {
  TranslateBloc() : super(const TranslateState()) {
    on<TrArabicEvent>(_onArabic);
    on<TrEnglishEvent>(_onEnglish);
  }

  void _onArabic(TrArabicEvent event, Emitter<TranslateState> emit) {
    if (state.languageCode != 'ar') emit(const TranslateState());
  }

  void _onEnglish(TrEnglishEvent event, Emitter<TranslateState> emit) {
    if (state.languageCode != 'en') {
      emit(const TranslateState(languageCode: 'en'));
    }
  }

  @override
  TranslateState? fromJson(Map<String, dynamic> json) =>
      TranslateState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(TranslateState state) => state.toMap();
}
