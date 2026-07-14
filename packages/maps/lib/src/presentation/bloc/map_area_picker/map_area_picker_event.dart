part of 'map_area_picker_bloc.dart';

sealed class MapAreaPickerEvent extends Equatable {
  const MapAreaPickerEvent();

  @override
  List<Object?> get props => [];
}

final class MapAreaPickerStarted extends MapAreaPickerEvent {
  const MapAreaPickerStarted({
    this.initialPosition,
    this.initialAddress,
    this.localeIdentifier,
  });

  final LatLng? initialPosition;
  final String? initialAddress;
  final String? localeIdentifier;

  @override
  List<Object?> get props => [
        initialPosition,
        initialAddress,
        localeIdentifier,
      ];
}

final class MapAreaPickerLocationChanged extends MapAreaPickerEvent {
  const MapAreaPickerLocationChanged(
    this.position, {
    this.cameraSource = MapAreaPickerCameraSource.user,
  });

  final LatLng position;
  final MapAreaPickerCameraSource cameraSource;

  @override
  List<Object?> get props => [position, cameraSource];
}

final class MapAreaPickerQueryChanged extends MapAreaPickerEvent {
  const MapAreaPickerQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class MapAreaPickerPredictionSelected extends MapAreaPickerEvent {
  const MapAreaPickerPredictionSelected(this.prediction);

  final PlacePrediction prediction;

  @override
  List<Object?> get props => [prediction];
}

final class MapAreaPickerPredictionsCleared extends MapAreaPickerEvent {
  const MapAreaPickerPredictionsCleared();
}

final class MapAreaPickerConfirmed extends MapAreaPickerEvent {
  const MapAreaPickerConfirmed();
}
