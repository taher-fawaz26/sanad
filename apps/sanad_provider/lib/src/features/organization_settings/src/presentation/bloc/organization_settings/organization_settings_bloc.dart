import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/category_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/me_media_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/social_profiles_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_settings_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/working_hours_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_organization_settings_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_working_hours_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_service_provider_settings_params.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_service_provider_settings_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_working_hours_usecase.dart';
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
    required OrganizationSettingsRepository organizationSettingsRepository,
    required WorkingHoursRepository workingHoursRepository,
  }) : _getOrganizationSettings = getOrganizationSettings,
       _updateServiceProviderSettings = updateServiceProviderSettings,
       _getCompletion = getCompletion,
       _getWorkingHours = getWorkingHours,
       _updateWorkingHours = updateWorkingHours,
       _getCategories = getCategories,
       _organizationSettingsRepository = organizationSettingsRepository,
       _workingHoursRepository = workingHoursRepository,
       super(const OrganizationSettingsState()) {
    on<OrganizationSettingsLoaded>(_onLoaded);
    on<OrganizationSettingsRefreshed>(_onLoaded);
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<OrganizationSettingsDescriptionSaved>(
      _onDescriptionSaved,
      transformer: droppable(),
    );
    on<OrganizationSettingsCategoriesSaved>(
      _onCategoriesSaved,
      transformer: droppable(),
    );
    on<OrganizationSettingsSocialProfilesSaved>(
      _onSocialProfilesSaved,
      transformer: droppable(),
    );
    on<OrganizationSettingsWorkingHoursSaved>(
      _onWorkingHoursSaved,
      transformer: droppable(),
    );
    on<OrganizationSettingsMediaUpdated>(_onMediaUpdated);
  }

  final GetOrganizationSettingsUseCase _getOrganizationSettings;
  final UpdateServiceProviderSettingsUseCase _updateServiceProviderSettings;
  final GetProviderCompletionUseCase _getCompletion;
  final GetWorkingHoursUseCase _getWorkingHours;
  final UpdateWorkingHoursUseCase _updateWorkingHours;
  final GetCategoriesUseCase _getCategories;
  final OrganizationSettingsRepository _organizationSettingsRepository;
  final WorkingHoursRepository _workingHoursRepository;

  /// A generously large page size stands in for "the full catalog" — there
  /// is no dedicated "fetch all categories" endpoint, and the category
  /// picker needs the complete list to select from.
  static const _categoryCatalogLimit = 100;

  Future<void> _onLoaded(
    OrganizationSettingsEvent event,
    Emitter<OrganizationSettingsState> emit,
  ) async {
    // Cache-first, stale-while-revalidate — only for the initial open, not
    // an explicit pull-to-refresh: seed instantly from whatever's cached,
    // then always continue to the network fetch below in the background.
    // Provider-completion and the category catalog are deliberately not
    // cached (see OrganizationSettingsCacheDataSource doc) — they stay null
    // until the network responds, same as before.
    var seededFromCache = false;
    if (event is OrganizationSettingsLoaded) {
      final cachedOrganization = await _organizationSettingsRepository
          .getCachedOrganizationSettings();
      if (cachedOrganization != null) {
        final cachedWorkingHours = await _workingHoursRepository
            .getCachedWorkingHours();
        seededFromCache = true;
        emit(
          state.copyWith(
            status: RequestStatus.success,
            organization: cachedOrganization,
            workingHours: cachedWorkingHours ?? const [],
          ),
        );
      }
    }

    if (!seededFromCache) {
      emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    }

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
      (failure) {
        // Cached content is already on screen and still valid — a
        // background-refresh failure shouldn't interrupt the user with an
        // error over data that's perfectly fine to keep looking at.
        if (seededFromCache) return;
        emit(
          state.copyWith(status: RequestStatus.failure, failure: failure),
        );
      },
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
        if (organization == null) {
          emit(state.copyWith(saveStatus: RequestStatus.success));
          return;
        }
        final merged = merge(organization);
        emit(
          state.copyWith(
            saveStatus: RequestStatus.success,
            organization: merged,
          ),
        );
        unawaited(
          _organizationSettingsRepository.cacheOrganizationSettings(merged),
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
      (availability) {
        // WorkingHoursRepositoryImpl.updateWorkingHours already
        // write-throughs the PUT response to the cache, so no separate
        // cache call is needed here.
        emit(
          state.copyWith(
            saveStatus: RequestStatus.success,
            workingHours: availability ?? const [],
          ),
        );
      },
    );
  }

  /// Merges a successfully-uploaded cover/logo URL into [state.organization]
  /// so it doesn't go stale (or get silently overwritten by a stale cached
  /// value) until the next full network refresh. The upload/its own
  /// loading-progress state is already owned and shown by
  /// [IdentityHeaderBloc] — this is a pure local-state sync, not a mutation
  /// of its own, so it doesn't touch `saveStatus`.
  void _onMediaUpdated(
    OrganizationSettingsMediaUpdated event,
    Emitter<OrganizationSettingsState> emit,
  ) {
    final organization = state.organization;
    if (organization == null) return;

    final media = MeMediaEntity(
      id:
          switch (event.slot) {
            OrganizationMediaSlot.cover => organization.coverImage?.id,
            OrganizationMediaSlot.logo => organization.profileImage?.id,
          } ??
          event.url,
      url: event.url,
    );

    final merged = switch (event.slot) {
      OrganizationMediaSlot.cover => organization.copyWith(coverImage: media),
      OrganizationMediaSlot.logo => organization.copyWith(profileImage: media),
    };

    emit(state.copyWith(organization: merged));
    unawaited(
      _organizationSettingsRepository.cacheOrganizationSettings(merged),
    );
  }
}
