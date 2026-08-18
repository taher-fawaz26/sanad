/// Reusable document upload → OCR extract → review → submit workflow.
///
/// One `DocumentFlowBloc`, one upload/extract/submit pipeline, one set of
/// shared widgets. Each consuming feature (registration, organization
/// settings, ...) supplies only a `DocumentFlowRepository` implementation,
/// its own endpoints/request/response mapping, a `DocumentFlowConfig`, and
/// its own screens.
library;

// DI / module.
export 'src/di/document_flow_di.dart';
// Domain — entities & value objects.
export 'src/domain/entities/document_flow_config.dart';
export 'src/domain/entities/document_flow_context.dart';
export 'src/domain/entities/document_media.dart';
export 'src/domain/entities/document_repair_target.dart';
export 'src/domain/entities/document_type.dart';
export 'src/domain/entities/document_validation.dart';
export 'src/domain/entities/extracted_document.dart';
export 'src/domain/entities/extracted_field.dart';
// Domain — failures.
export 'src/domain/failures/document_flow_failure.dart';
// Domain — repository contract & params.
export 'src/domain/repositories/document_flow_repository.dart';
export 'src/domain/usecases/document_flow_params.dart';
// Domain — use cases.
export 'src/domain/usecases/extract_documents_usecase.dart';
export 'src/domain/usecases/fetch_documents_usecase.dart';
export 'src/domain/usecases/submit_documents_usecase.dart';
export 'src/domain/usecases/upload_media_usecase.dart';
export 'src/module/document_flow_module.dart';
// Presentation — bloc, controller.
export 'src/presentation/bloc/document_flow_bloc.dart';
export 'src/presentation/controller/document_flow_controller.dart';
// Presentation — shared widgets.
export 'src/presentation/widgets/document_flow_capture.dart';
export 'src/presentation/widgets/document_preview.dart';
export 'src/presentation/widgets/document_upload_card.dart';
export 'src/presentation/widgets/extracted_fields_view.dart';
