import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:maps/src/config/maps_config.dart';
import 'package:maps/src/data/cache/geocoding_cache.dart';
import 'package:maps/src/data/repositories/geocoding_repository_impl.dart';
import 'package:maps/src/data/repositories/google_nearby_areas_repository_impl.dart';
import 'package:maps/src/data/repositories/google_reverse_geocode_place_repository_impl.dart';
import 'package:maps/src/data/repositories/location_repository_impl.dart';
import 'package:maps/src/data/repositories/locations_repository_impl.dart';
import 'package:maps/src/data/repositories/places_repository_impl.dart';
import 'package:maps/src/domain/repositories/geocoding_repository.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:maps/src/domain/repositories/nearby_areas_repository.dart';
import 'package:maps/src/domain/repositories/places_repository.dart';
import 'package:maps/src/domain/repositories/reverse_geocode_place_repository.dart';
import 'package:maps/src/domain/usecases/check_location_permission_usecase.dart';
import 'package:maps/src/domain/usecases/forward_geocode_usecase.dart';
import 'package:maps/src/domain/usecases/get_cities_usecase.dart';
import 'package:maps/src/domain/usecases/get_current_location_usecase.dart';
import 'package:maps/src/domain/usecases/get_place_details_usecase.dart';
import 'package:maps/src/domain/usecases/open_device_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/open_location_settings_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_coverage_location_usecase.dart';
import 'package:maps/src/domain/usecases/resolve_nearby_areas_usecase.dart';
import 'package:maps/src/domain/usecases/reverse_geocode_place_usecase.dart';
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
    _warnIfKeyless(config);

    sl
      ..registerLazySingleton<MapsConfig>(() => config)
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
        () {
          if (!config.placesEnabled) {
            // Cause already reported once, eagerly, by _warnIfKeyless.
            return const NoopNearbyAreasRepository();
          }
          return GoogleNearbyAreasRepositoryImpl(
            apiKey: config.placesApiKey!,
            dio: _createPlacesDio(),
            countryCode: config.countryCode,
            gridSpacingKm: config.servingAreaDiscovery.gridSpacingKm,
            maxSamples: config.servingAreaDiscovery.maxSamples,
            concurrency: config.servingAreaDiscovery.concurrency,
          );
        },
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
      )
      ..registerLazySingleton(
        () => OpenDeviceLocationSettingsUseCase(sl<LocationRepository>()),
      )
      ..registerLazySingleton(
        () => CheckLocationPermissionUseCase(sl<LocationRepository>()),
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

      // Google-only: reverse-geocode a coordinate to a real Google place_id
      // (the REST Geocoding API), so a map-dragged pin / current-location fix
      // carries the Place ID the backend requires without forcing the user to
      // pick a search result. Not available for the backend/OSM providers.
      if (config.placesProvider == PlacesProviderType.google) {
        sl
          ..registerLazySingleton<ReverseGeocodePlaceRepository>(
            () => GoogleReverseGeocodePlaceRepositoryImpl(
              apiKey: config.placesApiKey!,
              dio: _createPlacesDio(),
              countryCode: config.countryCode,
            ),
          )
          ..registerLazySingleton(
            () => ReverseGeocodePlaceUseCase(
              sl<ReverseGeocodePlaceRepository>(),
            ),
          );
      }
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
          getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
          openDeviceLocationSettingsUseCase:
              sl<OpenDeviceLocationSettingsUseCase>(),
          checkLocationPermissionUseCase: sl<CheckLocationPermissionUseCase>(),
          searchPlacesUseCase: config.placesEnabled
              ? sl<SearchPlacesUseCase>()
              : null,
          getPlaceDetailsUseCase: config.placesEnabled
              ? sl<GetPlaceDetailsUseCase>()
              : null,
          reverseGeocodePlaceUseCase:
              config.placesEnabled &&
                  config.placesProvider == PlacesProviderType.google
              ? sl<ReverseGeocodePlaceUseCase>()
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

  /// Reports a keyless Maps configuration at init, eagerly and at error level
  /// so it survives release log filtering (`appLogger` keeps warning-and-above
  /// in release builds).
  ///
  /// Only `sanad_provider` registers Maps, and every provider build needs the
  /// key, so an empty [MapsConfig.placesApiKey] is always a build
  /// misconfiguration — never a supported mode. Left silent it degrades into a
  /// dead end that looks like a feature bug: the map still renders (the native
  /// SDK reads its own manifest key) and a dragged pin still reverse-geocodes
  /// via the keyless platform geocoder, but no Google `place_id` can be
  /// resolved and Places autocomplete is inert — so Confirm on the branch
  /// location picker stays disabled forever with no stated cause (SAN-823).
  static void _warnIfKeyless(MapsConfig config) {
    if (config.placesEnabled) return;
    appLogger.e(
      '[MapsDI] MAPS_API_KEY is missing — Places autocomplete, Google '
      'place_id resolution and serving-area discovery are ALL disabled. A '
      'branch location can never be confirmed in this build. Build with '
      '`melos run build:provider:android`, or set MAPS_API_KEY in '
      'android/local.properties (see docs/CONFIGURATION.md).',
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
