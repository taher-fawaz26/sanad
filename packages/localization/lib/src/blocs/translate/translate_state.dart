part of 'translate_bloc.dart';

class TranslateState extends Equatable {
  const TranslateState({this.languageCode = 'ar'});

  factory TranslateState.fromMap(Map<String, dynamic> map) {
    final dynamic raw = map['language_code'];
    var code = 'ar';
    if (raw is String) {
      final normalized = raw.toLowerCase();
      if (normalized == 'en' || normalized == 'ar') code = normalized;
    }
    return TranslateState(languageCode: code);
  }

  final String languageCode;

  @override
  List<Object> get props => [languageCode];

  Map<String, dynamic> toMap() => {'language_code': languageCode};
}
