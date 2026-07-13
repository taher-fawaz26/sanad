part of 'location_picker_bloc.dart';

sealed class LocationPickerEvent extends Equatable {
  const LocationPickerEvent();

  @override
  List<Object?> get props => [];
}

final class LocationPickerStarted extends LocationPickerEvent {
  const LocationPickerStarted();
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
