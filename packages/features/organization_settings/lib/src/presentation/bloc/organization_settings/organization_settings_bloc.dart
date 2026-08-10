import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organization_settings/src/domain/entities/category_entity.dart';
import 'package:organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:organization_settings/src/domain/entities/social_profiles_entity.dart';
import 'package:organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:organization_settings/src/domain/usecases/get_organization_settings_usecase.dart';
import 'package:organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';
import 'package:organization_settings/src/domain/usecases/get_working_hours_usecase.dart';
import 'package:organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';
import 'package:organization_settings/src/domain/usecases/update_service_provider_settings_usecase.dart';
import 'package:organization_settings/src/domain/usecases/update_working_hours_usecase.dart';
import 'package:services/services.dart'
    show GetCategoriesParams, GetCategoriesUseCase;

part 'organization_settings_event.dart';
part 'organization_settings_state.dart';

/// Single source of truth for the entire Organization Settings feature.
///
/// Loads the organization's business profile via `GET /settings`, its
/// working hours (`GET service-provider/working-hours`), its
/// profile-completion checklist (`GET service-provider/completion`), and the
/// category catalog (`GET /categories`, via the `services` package) — every
/// section on the general settings page reads from this one bloc instead of
/// independent models or mocked state.
///
/// Description/category/social-profile edits go through `PATCH
/// service-provider/settings`, which returns `204 No Content`; on success
/// the sent fields are merged straight into the in-memory
/// [OrganizationProfileEntity] rather than re-fetching `GET /settings`.
/// Working-hours edits go through `PUT service-provider/working-hours`,
/// which does return the persisted schedule, so that response is used
/// directly.
class OrganizationSettingsBloc
    extends Bloc<OrganizationSettingsEvent, OrganizationSettingsState> {
  OrganizationSettingsBloc({
    required GetOrganizationSettingsUseCase getOrganizationSettings,
    required UpdateServiceProviderSettingsUseCase updateServiceProviderSettings,
    required GetProviderCompletionUseCase getCompletion,
    required GetWorkingHoursUseCase getWorkingHours,
    required UpdateWorkingHoursUseCase updateWorkingHours,
    required GetCategoriesUseCase getCategories,
  }) : _getOrganizationSettings = getOrganizationSettings,
       _updateServiceProviderSettings = updateServiceProviderSettings,
       _getCompletion = getCompletion,
       _getWorkingHours = getWorkingHours,
       _updateWorkingHours = updateWorkingHours,
       _getCategories = getCategories,
       super(const OrganizationSettingsState()) {
    on<OrganizationSettingsLoaded>(_onLoaded);
    on<OrganizationSettingsRefreshed>(_onLoaded);
    on<OrganizationSettingsDescriptionSaved>(_onDescriptionSaved);
    on<OrganizationSettingsCategoriesSaved>(_onCategoriesSaved);
    on<OrganizationSettingsSocialProfilesSaved>(_onSocialProfilesSaved);
    on<OrganizationSettingsWorkingHoursSaved>(_onWorkingHoursSaved);
  }

  final GetOrganizationSettingsUseCase _getOrganizationSettings;
  final UpdateServiceProviderSettingsUseCase _updateServiceProviderSettings;
  final GetProviderCompletionUseCase _getCompletion;
  final GetWorkingHoursUseCase _getWorkingHours;
  final UpdateWorkingHoursUseCase _updateWorkingHours;
  final GetCategoriesUseCase _getCategories;

  /// A generously large page size stands in for "the full catalog" — there
  /// is no dedicated "fetch all categories" endpoint, and the category
  /// picker needs the complete list to select from.
  static const _categoryCatalogLimit = 100;

  Future<void> _onLoaded(
    OrganizationSettingsEvent event,
    Emitter<OrganizationSettingsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final organizationFuture = _getOrganizationSettings(const NoParams()).run();
    final workingHoursFuture = _getWorkingHours(const NoParams()).run();
    final completionFuture = _getCompletion(const NoParams()).run();
    final categoriesFuture = _getCategories(
      const GetCategoriesParams(limit: _categoryCatalogLimit),
    ).run();

    final organizationResult = await organizationFuture;
    final workingHoursResult = await workingHoursFuture;
    final completionResult = await completionFuture;
    final categoriesResult = await categoriesFuture;

    organizationResult.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (organization) => emit(
        state.copyWith(
          status: RequestStatus.success,
          organization: organization,
          workingHours: workingHoursResult.getOrElse((_) => null) ?? const [],
          completion: completionResult.fold((_) => null, (value) => value),
          categoryCatalog: categoriesResult.fold(
            (_) => const [],
            (paged) => paged.items
                .map(
                  (record) => CategoryEntity(id: record.id, name: record.name),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _onDescriptionSaved(
    OrganizationSettingsDescriptionSaved event,
    Emitter<OrganizationSettingsState> emit,
  ) => _patchSettings(
    emit,
    UpdateServiceProviderSettingsParams(description: event.description),
    (organization) => organization.copyWith(description: event.description),
  );

  Future<void> _onCategoriesSaved(
    OrganizationSettingsCategoriesSaved event,
    Emitter<OrganizationSettingsState> emit,
  ) => _patchSettings(
    emit,
    UpdateServiceProviderSettingsParams(
      categoryIds: event.categories.map((category) => category.id).toList(),
    ),
    (organization) => organization.copyWith(categories: event.categories),
  );

  Future<void> _onSocialProfilesSaved(
    OrganizationSettingsSocialProfilesSaved event,
    Emitter<OrganizationSettingsState> emit,
  ) => _patchSettings(
    emit,
    UpdateServiceProviderSettingsParams(
      socialProfiles: _socialProfilesMap(event.socialProfiles),
    ),
    (organization) =>
        organization.copyWith(socialProfiles: event.socialProfiles),
  );

  Map<String, String> _socialProfilesMap(SocialProfilesEntity profiles) => {
    if (profiles.facebook != null) 'facebook': profiles.facebook!,
    if (profiles.x != null) 'x': profiles.x!,
    if (profiles.tiktok != null) 'tiktok': profiles.tiktok!,
    if (profiles.instagram != null) 'instagram': profiles.instagram!,
    if (profiles.websiteUrl != null) 'website': profiles.websiteUrl!,
  };

  Future<void> _patchSettings(
    Emitter<OrganizationSettingsState> emit,
    UpdateServiceProviderSettingsParams params,
    OrganizationProfileEntity Function(OrganizationProfileEntity organization)
    merge,
  ) async {
    emit(
      state.copyWith(saveStatus: RequestStatus.loading, clearSaveFailure: true),
    );

    final result = await _updateServiceProviderSettings(params).run();

    result.fold(
      (failure) => emit(
        state.copyWith(saveStatus: RequestStatus.failure, saveFailure: failure),
      ),
      (_) {
        final organization = state.organization;
        emit(
          state.copyWith(
            saveStatus: RequestStatus.success,
            organization: organization == null ? null : merge(organization),
          ),
        );
      },
    );
  }

  Future<void> _onWorkingHoursSaved(
    OrganizationSettingsWorkingHoursSaved event,
    Emitter<OrganizationSettingsState> emit,
  ) async {
    emit(
      state.copyWith(saveStatus: RequestStatus.loading, clearSaveFailure: true),
    );

    final result = await _updateWorkingHours(event.availability).run();

    result.fold(
      (failure) => emit(
        state.copyWith(saveStatus: RequestStatus.failure, saveFailure: failure),
      ),
      (availability) => emit(
        state.copyWith(
          saveStatus: RequestStatus.success,
          workingHours: availability ?? const [],
        ),
      ),
    );
  }
}
