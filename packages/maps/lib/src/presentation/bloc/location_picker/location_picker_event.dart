part of 'location_picker_bloc.dart';

sealed class LocationPickerEvent extends Equatable {
  const LocationPickerEvent();

  @override
  List<Object?> get props => [];
}

final class LocationPickerStarted extends LocationPickerEvent {
  const LocationPickerStarted({
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

final class LocationPickerCameraIdle extends LocationPickerEvent {
  const LocationPickerCameraIdle(this.position);

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

final class LocationPickerSearchSubmitted extends LocationPickerEvent {
  const LocationPickerSearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class LocationPickerSettingsRequested extends LocationPickerEvent {
  const LocationPickerSettingsRequested();
}

final class LocationPickerQueryChanged extends LocationPickerEvent {
  const LocationPickerQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class LocationPickerPredictionSelected extends LocationPickerEvent {
  const LocationPickerPredictionSelected(this.prediction);

  final PlacePrediction prediction;

  @override
  List<Object?> get props => [prediction];
}

final class LocationPickerPredictionsCleared extends LocationPickerEvent {
  const LocationPickerPredictionsCleared();
}
