/// Sanad Maps Platform — reusable map engine, controllers, and widgets
/// for all features that need geographic capabilities.
library;

export 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        BitmapDescriptor,
        CameraPosition,
        CameraUpdate,
        Circle,
        CircleId,
        GoogleMapController,
        LatLng,
        LatLngBounds,
        MapType,
        Marker,
        MarkerId,
        Polygon,
        PolygonId,
        Polyline,
        PolylineId;

export 'src/config/maps_config.dart';
export 'src/data/repositories/geocoding_repository_impl.dart';
export 'src/data/repositories/location_repository_impl.dart';
export 'src/data/repositories/places_repository_impl.dart';
export 'src/di/maps_di.dart';
export 'src/domain/entities/coverage_location.dart';
export 'src/domain/entities/coverage_mode.dart';
export 'src/domain/entities/map_area_picker_result.dart';
export 'src/domain/entities/map_event.dart';
export 'src/domain/entities/map_position.dart';
export 'src/domain/entities/map_region.dart';
export 'src/domain/entities/place_prediction.dart';
export 'src/domain/entities/serving_area.dart';
export 'src/domain/failures/places_failure.dart';
export 'src/domain/repositories/branch_serving_areas_repository.dart';
export 'src/domain/repositories/geocoding_repository.dart';
export 'src/domain/repositories/location_repository.dart';
export 'src/domain/repositories/places_repository.dart';
export 'src/domain/usecases/coverage_location_intent.dart';
export 'src/domain/usecases/forward_geocode_usecase.dart';
export 'src/domain/usecases/get_current_location_usecase.dart';
export 'src/domain/usecases/get_place_details_usecase.dart';
export 'src/domain/usecases/open_location_settings_usecase.dart';
export 'src/domain/usecases/resolve_coverage_location_usecase.dart';
export 'src/domain/usecases/resolve_nearby_areas_usecase.dart';
export 'src/domain/usecases/reverse_geocode_usecase.dart';
export 'src/domain/usecases/search_places_usecase.dart';
export 'src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
export 'src/presentation/bloc/location_picker/location_picker_bloc.dart';
export 'src/presentation/bloc/map_area_picker/map_area_picker_bloc.dart';
export 'src/presentation/controllers/map_camera_controller.dart';
export 'src/presentation/controllers/map_overlay_controller.dart';
export 'src/presentation/controllers/map_radius_controller.dart';
export 'src/presentation/controllers/serving_area_controller.dart';
export 'src/presentation/models/coverage_area_labels.dart';
export 'src/presentation/models/location_picker_labels.dart';
export 'src/presentation/models/location_picker_result.dart';
export 'src/presentation/models/map_area_picker_labels.dart';
export 'src/presentation/models/map_configuration.dart';
export 'src/presentation/models/place_search_status.dart';
export 'src/presentation/models/polygon_style.dart';
export 'src/presentation/models/polyline_style.dart';
export 'src/presentation/models/radius_overlay_style.dart';
export 'src/presentation/models/radius_preset.dart';
export 'src/presentation/utils/geo_math.dart';
export 'src/presentation/utils/radius_format.dart';
export 'src/presentation/widgets/animated_circle_overlay.dart';
export 'src/presentation/widgets/location_address_field.dart';
export 'src/presentation/widgets/location_picker_sheet.dart';
export 'src/presentation/widgets/map_area_picker.dart';
export 'src/presentation/widgets/map_control_bar.dart';
export 'src/presentation/widgets/map_location_picker.dart';
export 'src/presentation/widgets/map_my_location_button.dart';
export 'src/presentation/widgets/map_type_button.dart';
export 'src/presentation/widgets/map_zoom_controls.dart';
export 'src/presentation/widgets/place_search_bar.dart';
export 'src/presentation/widgets/place_search_field.dart';
export 'src/presentation/widgets/place_suggestions_overlay.dart';
export 'src/presentation/widgets/prediction_list.dart';
export 'src/presentation/widgets/prediction_tile.dart';
export 'src/presentation/widgets/radius_selector.dart';
export 'src/presentation/widgets/serving_area_chips.dart';
export 'src/services/backend_places_provider.dart';
export 'src/services/geocoding_service.dart';
export 'src/services/geocoding_service_impl.dart';
export 'src/services/google_places_provider.dart';
export 'src/services/location_failure_codes.dart';
export 'src/services/location_service.dart';
export 'src/services/location_service_impl.dart';
export 'src/services/osm_places_provider.dart';
export 'src/services/places_provider.dart';
export 'src/services/places_service.dart';
export 'src/services/places_service_impl.dart';
export 'src/widgets/app_google_map.dart';
