/// Sanad Maps Platform — reusable map engine, controllers, and widgets
/// for all features that need geographic capabilities.
///
/// The public surface is intentionally small: only the types features
/// consume (or that exist as documented extension points) are exported
/// here. Everything else is an internal implementation detail of the
/// package and must be reached through these public entry points.
library;

export 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        BitmapDescriptor,
        CameraPosition,
        CameraTargetBounds,
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

// Configuration & DI
export 'src/config/maps_config.dart';
export 'src/di/maps_di.dart';
export 'src/module/maps_module.dart';

// Domain entities (public value objects)
export 'src/domain/entities/city_entity.dart';
export 'src/domain/entities/country_entity.dart';
export 'src/domain/entities/coverage_mode.dart';
export 'src/domain/entities/map_area_picker_result.dart';
export 'src/domain/entities/place_prediction.dart';
export 'src/domain/entities/serving_area.dart';

// Domain failures (public surface for callers to pattern-match)
export 'src/domain/failures/locations_failure.dart';

// Domain use cases (locations)
export 'src/domain/usecases/get_cities_usecase.dart';

// Presentation — BLoCs consumed by features
export 'src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
export 'src/presentation/bloc/location_picker/location_picker_bloc.dart';

// Presentation — initial-camera resolution (UAE default, priority-based)
export 'src/presentation/camera/default_map_viewport.dart';
export 'src/presentation/camera/initial_camera_resolver.dart';

// Presentation — controllers used to drive maps from feature widgets
export 'src/presentation/controllers/map_camera_controller.dart';
export 'src/presentation/controllers/map_radius_controller.dart';

// Presentation — models used in public widget/bloc APIs
export 'src/presentation/models/location_picker_labels.dart';
export 'src/presentation/models/location_picker_result.dart';
export 'src/presentation/models/map_area_picker_labels.dart';
export 'src/presentation/models/place_search_status.dart';
export 'src/presentation/models/radius_overlay_style.dart';

// Presentation — utilities
export 'src/presentation/utils/radius_format.dart';

// Presentation — reusable widgets & sheets
export 'src/presentation/widgets/city_select_field.dart';
export 'src/presentation/widgets/location_picker_sheet.dart';
export 'src/presentation/widgets/map_area_picker.dart';
export 'src/presentation/widgets/place_search_sheet_body.dart';
export 'src/presentation/widgets/serving_area_chips.dart';

// Services — infrastructure wired by the host app's DI
export 'src/services/geocoding_service.dart';
export 'src/services/geocoding_service_impl.dart';
export 'src/services/location_failure_codes.dart';
export 'src/services/location_service.dart';
export 'src/services/location_service_impl.dart';

// Configured Google Map widget
export 'src/widgets/app_google_map.dart';
