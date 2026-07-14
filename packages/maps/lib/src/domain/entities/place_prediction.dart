import 'package:equatable/equatable.dart';

class PlacePrediction extends Equatable {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText:
          structured?['main_text'] as String? ??
          json['description'] as String,
      secondaryText: structured?['secondary_text'] as String? ?? '',
    );
  }

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  @override
  List<Object?> get props => [placeId, description, mainText, secondaryText];
}
