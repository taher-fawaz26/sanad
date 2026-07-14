import 'package:equatable/equatable.dart';

class PlacePrediction extends Equatable {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  @override
  List<Object?> get props => [placeId, description, mainText, secondaryText];
}
