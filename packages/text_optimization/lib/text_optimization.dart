/// Shared "Enhance with AI" text-optimization flow.
///
/// One domain contract and one `TextOptimizationCubit` that every
/// description field's AI-enhance affordance shares — call
/// `TextOptimizationDI.init` once at app bootstrap, then drop in
/// `AiEnhanceDescriptionField` wherever a description field needs the
/// AI-enhance action.
library;

export 'src/di/text_optimization_di.dart';
export 'src/domain/repositories/text_optimization_repository.dart';
export 'src/domain/usecases/optimize_text_usecase.dart';
export 'src/presentation/cubit/text_optimization_cubit.dart';
export 'src/presentation/widgets/ai_enhance_description_field.dart';
