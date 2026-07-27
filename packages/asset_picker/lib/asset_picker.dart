/// Sanad Asset Picker — the single source of truth for acquiring external
/// assets (camera, gallery, files, document scans).
///
/// The public surface is intentionally plugin-agnostic: `image_picker`,
/// `file_picker` and the scanning SDK are never exported. Features depend only
/// on the `AssetPicker` facade, the `AssetPickerService` contract, the domain
/// value objects, and the abstract provider interfaces (for custom sources).
///
/// See `README.md` for architecture, the public API, examples, and how to
/// extend providers.
library;

// Facade — the ergonomic entry point.
export 'src/asset_picker_facade.dart';

// DI, configuration & module wiring.
export 'src/di/asset_picker_config.dart';
export 'src/di/asset_picker_di.dart';
export 'src/di/asset_picker_module.dart';

// Domain — entities.
export 'src/domain/entities/asset_picker_options.dart';
export 'src/domain/entities/asset_picker_result.dart';
export 'src/domain/entities/picked_asset.dart';

// Domain — enums.
export 'src/domain/enums/asset_source.dart';
export 'src/domain/enums/asset_type.dart';

// Domain — failures (public so callers can pattern-match).
export 'src/domain/failures/asset_picker_exception.dart';

// Domain — service contract (the DI-registered abstraction).
export 'src/domain/services/asset_picker_service.dart';

// Domain — upload lifecycle model (foundation for future upload managers).
export 'src/domain/upload/upload_status.dart';
export 'src/domain/upload/uploadable_asset.dart';

// Domain — validation (public so apps can supply custom validators).
export 'src/domain/validation/asset_validation_error.dart';
export 'src/domain/validation/asset_validator.dart';

// Infrastructure — abstract provider contracts ONLY. Concrete plugin-backed
// implementations are intentionally NOT exported so third-party plugin types
// never leak across the package boundary.
export 'src/infrastructure/providers/camera_provider.dart';
export 'src/infrastructure/providers/file_provider.dart';
export 'src/infrastructure/providers/gallery_provider.dart';
export 'src/infrastructure/providers/scanner_provider.dart';

// Infrastructure — plugin-agnostic scanner tuning (no SDK types exposed).
export 'src/infrastructure/scanner/document_scanner_config.dart';

// Presentation — generic, reusable preview (dialog + full-screen page).
export 'src/presentation/preview/asset_preview.dart';
export 'src/presentation/preview/asset_preview_content.dart';
export 'src/presentation/preview/asset_preview_dialog.dart';
export 'src/presentation/preview/asset_preview_page.dart';

// Presentation — the auto-generated source sheet and its row widget.
export 'src/presentation/sheets/asset_source_sheet.dart';
export 'src/presentation/widgets/asset_picker_tile.dart';
export 'src/presentation/widgets/asset_thumbnail.dart';

// Theme — design-system-driven look & feel.
export 'src/theme/asset_picker_theme.dart';
