import 'package:maps/src/domain/entities/place_prediction.dart';

class PlacePredictionDto {
  const PlacePredictionDto._();

  static PlacePrediction fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText:
          structured?['main_text'] as String? ?? json['description'] as String,
      secondaryText: structured?['secondary_text'] as String? ?? '',
    );
  }
}
