import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:maps/src/config/maps_config.dart';
import 'package:maps/src/data/cache/geocoding_cache.dart';
import 'package:maps/src/data/repositories/geocoding_repository_impl.dart';
import 'package:maps/src/data/repositories/google_nearby_areas_repository_impl.dart';
import 'package:maps/src/data/repositories/location_repository_impl.dart';
import 'package:maps/src/data/repositories/locations_repository_impl.dart';
import 'package:maps/src/data/repositories/places_repository_impl.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/domain/repositories/places_repository.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_cities_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_coverage_location_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/search_places_usecase.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:maps/src/presentation/bloc/map_area_picker/map_area_picker_bloc.dart';
import 'package:maps/src/services/backend_places_provider.dart';
import 'package:maps/src/services/geocoding_service.dart';
import 'package:maps/src/services/google_places_provider.dart';
import 'package:maps/src/services/location_service.dart';
import 'package:maps/src/services/osm_places_provider.dart';
import 'package:maps/src/services/places_provider.dart';
import 'package:network/network.dart';

abstract final class MapsDI {
  MapsDI._();

  static void init({MapsConfig config = const MapsConfig()}) {
    sl
      ..registerLazySingleton<LocationsRepository>(
        () => LocationsRepositoryImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton(
        () => GetCitiesUseCase(sl<LocationsRepository>()),
      )
      ..registerLazySingleton<GeocodingCache>(GeocodingCache.new)
      ..registerLazySingleton<GeocodingRepository>(
        () => GeocodingRepositoryImpl(
          sl<GeocodingService>(),
          cache: sl<GeocodingCache>(),
        ),
      )
      ..registerLazySingleton<LocationRepository>(
        () => LocationRepositoryImpl(sl<LocationService>()),
      )
      ..registerLazySingleton(
        () => ReverseGeocodeUseCase(sl<GeocodingRepository>()),
      )
      ..registerLazySingleton(
        () => ForwardGeocodeUseCase(sl<GeocodingRepository>()),
      )
      ..registerLazySingleton<NearbyAreasRepository>(
        () => config.placesEnabled
            ? GoogleNearbyAreasRepositoryImpl(
                apiKey: config.placesApiKey!,
                dio: _createPlacesDio(),
                countryCode: config.countryCode,
              )
            : const NoopNearbyAreasRepository(),
      )
      ..registerLazySingleton(
        () => ResolveNearbyAreasUseCase(sl<NearbyAreasRepository>()),
      )
      ..registerLazySingleton(
        () => ResolveCoverageLocationUseCase(
          sl<ReverseGeocodeUseCase>(),
          sl<ResolveNearbyAreasUseCase>(),
        ),
      )
      ..registerLazySingleton(
        () => GetCurrentLocationUseCase(sl<LocationRepository>()),
      )
      ..registerLazySingleton(
        () => OpenLocationSettingsUseCase(sl<LocationRepository>()),
      );

    if (config.placesEnabled) {
      sl
        ..registerLazySingleton<PlacesProvider>(
          () => _createPlacesProvider(config),
        )
        ..registerLazySingleton<PlacesRepository>(
          () => PlacesRepositoryImpl(sl<PlacesProvider>()),
        )
        ..registerLazySingleton(
          () => SearchPlacesUseCase(sl<PlacesRepository>()),
        )
        ..registerLazySingleton(
          () => GetPlaceDetailsUseCase(sl<PlacesRepository>()),
        );
    }

    sl
      ..registerFactory(
        () => CoverageAreaBloc(
          resolveCoverageLocationUseCase: sl<ResolveCoverageLocationUseCase>(),
          getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
        ),
      )
      ..registerFactory(
        () => LocationPickerBloc(
          reverseGeocodeUseCase: sl<ReverseGeocodeUseCase>(),
          forwardGeocodeUseCase: sl<ForwardGeocodeUseCase>(),
          openLocationSettingsUseCase: sl<OpenLocationSettingsUseCase>(),
          searchPlacesUseCase: config.placesEnabled
              ? sl<SearchPlacesUseCase>()
              : null,
          getPlaceDetailsUseCase: config.placesEnabled
              ? sl<GetPlaceDetailsUseCase>()
              : null,
        ),
      )
      ..registerFactory(
        () => MapAreaPickerBloc(
          reverseGeocodeUseCase: sl<ReverseGeocodeUseCase>(),
          searchPlacesUseCase: config.placesEnabled
              ? sl<SearchPlacesUseCase>()
              : null,
          getPlaceDetailsUseCase: config.placesEnabled
              ? sl<GetPlaceDetailsUseCase>()
              : null,
        ),
      );
  }

  static PlacesProvider _createPlacesProvider(MapsConfig config) {
    return switch (config.placesProvider) {
      PlacesProviderType.google => GooglePlacesProvider(
        apiKey: config.placesApiKey!,
        dio: _createPlacesDio(),
        countryCode: config.countryCode,
      ),
      PlacesProviderType.backend => const BackendPlacesProvider(),
      PlacesProviderType.openStreetMap => const OsmPlacesProvider(),
    };
  }

  static Dio _createPlacesDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
  }
}
