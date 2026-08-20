// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/category_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/me_media_entity.dart';
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
import 'package:services/services.dart';

class _MockGetOrganizationSettings extends Mock
    implements GetOrganizationSettingsUseCase {}

class _MockUpdateServiceProviderSettings extends Mock
    implements UpdateServiceProviderSettingsUseCase {}

class _MockGetCompletion extends Mock implements GetProviderCompletionUseCase {}

class _MockGetWorkingHours extends Mock implements GetWorkingHoursUseCase {}

class _MockUpdateWorkingHours extends Mock
    implements UpdateWorkingHoursUseCase {}

class _MockGetCategories extends Mock implements GetCategoriesUseCase {}

class _MockOrganizationSettingsRepository extends Mock
    implements OrganizationSettingsRepository {}

class _MockWorkingHoursRepository extends Mock
    implements WorkingHoursRepository {}

void main() {
  late _MockGetOrganizationSettings getOrganizationSettings;
  late _MockUpdateServiceProviderSettings updateServiceProviderSettings;
  late _MockGetCompletion getCompletion;
  late _MockGetWorkingHours getWorkingHours;
  late _MockUpdateWorkingHours updateWorkingHours;
  late _MockGetCategories getCategories;
  late _MockOrganizationSettingsRepository organizationSettingsRepository;
  late _MockWorkingHoursRepository workingHoursRepository;

  final organization = OrganizationProfileEntity(
    id: 'org-1',
    categories: const [],
    status: BusinessProfileStatus.inReview,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    description: 'old description',
  );

  const completion = ProviderCompletionEntity(
    percentage: 50,
    requiredCompleted: 2,
    requiredTotal: 4,
    visibleToCustomers: false,
    items: [
      ProviderCompletionItemEntity(
        id: ProviderCompletionItemId.category,
        label: 'Category',
        completed: true,
        required: true,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const UpdateServiceProviderSettingsParams(description: 'x'),
    );
    registerFallbackValue(const GetCategoriesParams());
    registerFallbackValue(<WorkingHoursDayEntity>[]);
    registerFallbackValue(organization);
  });

  setUp(() {
    getOrganizationSettings = _MockGetOrganizationSettings();
    updateServiceProviderSettings = _MockUpdateServiceProviderSettings();
    getCompletion = _MockGetCompletion();
    getWorkingHours = _MockGetWorkingHours();
    updateWorkingHours = _MockUpdateWorkingHours();
    getCategories = _MockGetCategories();
    organizationSettingsRepository = _MockOrganizationSettingsRepository();
    workingHoursRepository = _MockWorkingHoursRepository();

    when(() => getOrganizationSettings(any())).thenAnswer(
      (_) => TaskEither.right(organization),
    );
    when(() => getWorkingHours(any())).thenAnswer(
      (_) => TaskEither.right(null),
    );
    when(() => getCompletion(any())).thenAnswer(
      (_) => TaskEither.right(completion),
    );
    when(() => getCategories(any())).thenAnswer(
      (_) => TaskEither.right(ServicesPagedResult.empty()),
    );
    // Cache miss by default — most tests below aren't exercising the
    // cache-first path, so this keeps their expectations to the pre-cache
    // "loading then success" shape.
    when(
      () => organizationSettingsRepository.getCachedOrganizationSettings(),
    ).thenAnswer((_) async => null);
    when(
      () => workingHoursRepository.getCachedWorkingHours(),
    ).thenAnswer((_) async => null);
    when(
      () => organizationSettingsRepository.cacheOrganizationSettings(any()),
    ).thenAnswer((_) async {});
  });

  OrganizationSettingsBloc build({bool isOwner = true}) =>
      OrganizationSettingsBloc(
        getOrganizationSettings: getOrganizationSettings,
        updateServiceProviderSettings: updateServiceProviderSettings,
        getCompletion: getCompletion,
        getWorkingHours: getWorkingHours,
        updateWorkingHours: updateWorkingHours,
        getCategories: getCategories,
        organizationSettingsRepository: organizationSettingsRepository,
        workingHoursRepository: workingHoursRepository,
        isOwner: isOwner,
      );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'loads organization, working hours, completion, and category catalog '
    'together',
    build: build,
    act: (bloc) => bloc.add(const OrganizationSettingsLoaded()),
    expect: () => [
      isA<OrganizationSettingsState>().having(
        (state) => state.status,
        'status',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having((state) => state.status, 'status', RequestStatus.success)
          .having((state) => state.organization, 'organization', organization)
          .having((state) => state.workingHours, 'workingHours', const [])
          .having((state) => state.completion, 'completion', completion),
    ],
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'isOwner: false (RBAC Phase 7G) — never calls getCompletion or '
    'getWorkingHours, the same worker/manager Settings-tab 403 bug already '
    'fixed for Services and Workers',
    build: () => build(isOwner: false),
    act: (bloc) => bloc.add(const OrganizationSettingsLoaded()),
    expect: () => [
      isA<OrganizationSettingsState>().having(
        (state) => state.status,
        'status',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having((state) => state.status, 'status', RequestStatus.success)
          .having((state) => state.organization, 'organization', organization)
          .having((state) => state.workingHours, 'workingHours', const [])
          .having((state) => state.completion, 'completion', isNull),
    ],
    verify: (_) {
      verifyNever(() => getCompletion(any()));
      verifyNever(() => getWorkingHours(any()));
      verifyNever(() => workingHoursRepository.getCachedWorkingHours());
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a cache hit seeds instantly (no loading state) then the background '
    'network refresh overwrites it once it resolves',
    build: () {
      when(
        () => organizationSettingsRepository.getCachedOrganizationSettings(),
      ).thenAnswer((_) async => organization);
      when(
        () => workingHoursRepository.getCachedWorkingHours(),
      ).thenAnswer((_) async => const []);
      return build();
    },
    act: (bloc) => bloc.add(const OrganizationSettingsLoaded()),
    expect: () => [
      // No RequestStatus.loading emission — the cache hit renders instantly.
      isA<OrganizationSettingsState>()
          .having((state) => state.status, 'status', RequestStatus.success)
          .having((state) => state.organization, 'organization', organization)
          .having((state) => state.workingHours, 'workingHours', const []),
      isA<OrganizationSettingsState>()
          .having((state) => state.status, 'status', RequestStatus.success)
          .having((state) => state.organization, 'organization', organization)
          .having((state) => state.completion, 'completion', completion),
    ],
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'isOwner: false (RBAC Phase 7G) — a cache hit does not read the cached '
    'working hours either, since a non-owner never wrote any',
    build: () {
      when(
        () => organizationSettingsRepository.getCachedOrganizationSettings(),
      ).thenAnswer((_) async => organization);
      return build(isOwner: false);
    },
    act: (bloc) => bloc.add(const OrganizationSettingsLoaded()),
    verify: (_) {
      verifyNever(() => workingHoursRepository.getCachedWorkingHours());
      verifyNever(() => getCompletion(any()));
      verifyNever(() => getWorkingHours(any()));
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a cache hit carries coverImage/profileImage through to the emitted '
    'state — regression for the reported "images show as placeholders" bug',
    build: () {
      final withImages = organization.copyWith(
        coverImage: const MeMediaEntity(id: 'cover-1', url: 'cover-url'),
        profileImage: const MeMediaEntity(id: 'logo-1', url: 'logo-url'),
      );
      when(
        () => organizationSettingsRepository.getCachedOrganizationSettings(),
      ).thenAnswer((_) async => withImages);
      when(
        () => workingHoursRepository.getCachedWorkingHours(),
      ).thenAnswer((_) async => const []);
      when(() => getOrganizationSettings(any())).thenAnswer(
        (_) => TaskEither.right(withImages),
      );
      return build();
    },
    act: (bloc) => bloc.add(const OrganizationSettingsLoaded()),
    verify: (bloc) {
      expect(bloc.state.organization?.coverImage?.url, 'cover-url');
      expect(bloc.state.organization?.profileImage?.url, 'logo-url');
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a cache hit followed by a network failure keeps the cached content '
    'on screen instead of surfacing an error',
    build: () {
      when(
        () => organizationSettingsRepository.getCachedOrganizationSettings(),
      ).thenAnswer((_) async => organization);
      when(
        () => workingHoursRepository.getCachedWorkingHours(),
      ).thenAnswer((_) async => const []);
      when(() => getOrganizationSettings(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
      return build();
    },
    act: (bloc) => bloc.add(const OrganizationSettingsLoaded()),
    expect: () => [
      isA<OrganizationSettingsState>()
          .having((state) => state.status, 'status', RequestStatus.success)
          .having(
            (state) => state.organization,
            'organization',
            organization,
          ),
    ],
    verify: (bloc) {
      expect(bloc.state.status, RequestStatus.success);
      expect(bloc.state.organization, organization);
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'saving a description PATCHes service-provider/settings and merges the '
    'result locally instead of re-fetching',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.right(unit),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsDescriptionSaved('new description'),
    ),
    expect: () => [
      // The draft is stashed as pendingDescription before the PATCH fires,
      // so a failed save can re-seed the edit sheet (SAN-567).
      isA<OrganizationSettingsState>().having(
        (state) => state.pendingDescription,
        'pendingDescription',
        'new description',
      ),
      isA<OrganizationSettingsState>().having(
        (state) => state.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having(
            (state) => state.saveStatus,
            'saveStatus',
            RequestStatus.success,
          )
          .having(
            (state) => state.organization?.description,
            'organization.description',
            'new description',
          )
          .having(
            (state) => state.pendingDescription,
            'pendingDescription',
            isNull,
          ),
    ],
    verify: (_) {
      final captured =
          verify(
                () => updateServiceProviderSettings(captureAny()),
              ).captured.single
              as UpdateServiceProviderSettingsParams;
      expect(captured.description, 'new description');
      expect(captured.categoryIds, isNull);
      expect(captured.socialProfiles, isNull);
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'saving categories sends only real backend category ids and merges the '
    'full entities back locally',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.right(unit),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsCategoriesSaved([
        CategoryEntity(id: 'cat-1', name: 'Cleaning'),
      ]),
    ),
    expect: () => [
      isA<OrganizationSettingsState>().having(
        (state) => state.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>().having(
        (state) => state.organization?.categories,
        'organization.categories',
        const [CategoryEntity(id: 'cat-1', name: 'Cleaning')],
      ),
    ],
    verify: (_) {
      final captured =
          verify(
                () => updateServiceProviderSettings(captureAny()),
              ).captured.single
              as UpdateServiceProviderSettingsParams;
      expect(captured.categoryIds, ['cat-1']);
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'saving social profiles maps the x/website keys the backend expects',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.right(unit),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsSocialProfilesSaved(
        SocialProfilesEntity(x: 'https://x.com/sanad', websiteUrl: 'sanad.co'),
      ),
    ),
    verify: (_) {
      final captured =
          verify(
                () => updateServiceProviderSettings(captureAny()),
              ).captured.single
              as UpdateServiceProviderSettingsParams;
      expect(captured.socialProfiles, {
        'x': 'https://x.com/sanad',
        'website': 'sanad.co',
      });
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a failed description save surfaces saveFailure and preserves the '
    'attempted text as pendingDescription (SAN-567) — the organization '
    'entity is left untouched',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.left(const NetworkFailure(message: 'errors.timeout')),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsDescriptionSaved('attempted text'),
    ),
    expect: () => [
      isA<OrganizationSettingsState>()
          .having(
            (state) => state.pendingDescription,
            'pendingDescription',
            'attempted text',
          )
          .having(
            (state) => state.saveStatus,
            'saveStatus',
            RequestStatus.initial,
          ),
      isA<OrganizationSettingsState>().having(
        (state) => state.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having(
            (state) => state.saveStatus,
            'saveStatus',
            RequestStatus.failure,
          )
          .having(
            (state) => state.saveFailure,
            'saveFailure',
            isA<NetworkFailure>(),
          )
          .having(
            (state) => state.pendingDescription,
            'pendingDescription',
            'attempted text',
          )
          .having(
            (state) => state.organization?.description,
            'organization.description',
            organization.description,
          ),
    ],
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a successful description save clears pendingDescription',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
      pendingDescription: 'stale draft',
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.right(unit),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsDescriptionSaved('new description'),
    ),
    expect: () => [
      isA<OrganizationSettingsState>().having(
        (state) => state.pendingDescription,
        'pendingDescription',
        'new description',
      ),
      isA<OrganizationSettingsState>().having(
        (state) => state.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having(
            (state) => state.saveStatus,
            'saveStatus',
            RequestStatus.success,
          )
          .having(
            (state) => state.pendingDescription,
            'pendingDescription',
            isNull,
          ),
    ],
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a failed categories save surfaces saveFailure and leaves categories '
    'unchanged',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsCategoriesSaved([
        CategoryEntity(id: 'cat-1', name: 'Cleaning'),
      ]),
    ),
    verify: (bloc) {
      expect(bloc.state.saveStatus, RequestStatus.failure);
      expect(bloc.state.saveFailure, isA<ServerFailure>());
      expect(bloc.state.organization?.categories, organization.categories);
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a failed social profiles save surfaces saveFailure and leaves social '
    'profiles unchanged',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateServiceProviderSettings(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsSocialProfilesSaved(
        SocialProfilesEntity(x: 'https://x.com/sanad'),
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.saveStatus, RequestStatus.failure);
      expect(bloc.state.saveFailure, isA<ServerFailure>());
      expect(
        bloc.state.organization?.socialProfiles,
        organization.socialProfiles,
      );
    },
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'a failed working hours save surfaces saveFailure and leaves '
    'workingHours unchanged',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
      workingHours: const [
        WorkingHoursDayEntity(
          day: 'Sunday',
          slots: [WorkingHoursSlotEntity(from: '10:00', to: '16:00')],
        ),
      ],
    ),
    setUp: () {
      when(() => updateWorkingHours(any())).thenAnswer(
        (_) => TaskEither.left(const NetworkFailure(message: 'errors.timeout')),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsWorkingHoursSaved([
        WorkingHoursDayEntity(
          day: 'Saturday',
          slots: [WorkingHoursSlotEntity(from: '09:00', to: '18:00')],
        ),
      ]),
    ),
    expect: () => [
      isA<OrganizationSettingsState>().having(
        (state) => state.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having(
            (state) => state.saveStatus,
            'saveStatus',
            RequestStatus.failure,
          )
          .having(
            (state) => state.saveFailure,
            'saveFailure',
            isA<NetworkFailure>(),
          )
          .having(
            (state) => state.workingHours,
            'workingHours',
            const [
              WorkingHoursDayEntity(
                day: 'Sunday',
                slots: [WorkingHoursSlotEntity(from: '10:00', to: '16:00')],
              ),
            ],
          ),
    ],
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'saving working hours uses the PUT response directly, no re-fetch',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
    ),
    setUp: () {
      when(() => updateWorkingHours(any())).thenAnswer(
        (_) => TaskEither.right(const [
          WorkingHoursDayEntity(
            day: 'Saturday',
            slots: [WorkingHoursSlotEntity(from: '09:00', to: '18:00')],
          ),
        ]),
      );
    },
    act: (bloc) => bloc.add(
      const OrganizationSettingsWorkingHoursSaved([
        WorkingHoursDayEntity(
          day: 'Saturday',
          slots: [WorkingHoursSlotEntity(from: '09:00', to: '18:00')],
        ),
      ]),
    ),
    expect: () => [
      isA<OrganizationSettingsState>().having(
        (state) => state.saveStatus,
        'saveStatus',
        RequestStatus.loading,
      ),
      isA<OrganizationSettingsState>()
          .having(
            (state) => state.saveStatus,
            'saveStatus',
            RequestStatus.success,
          )
          .having(
            (state) => state.workingHours,
            'workingHours',
            const [
              WorkingHoursDayEntity(
                day: 'Saturday',
                slots: [WorkingHoursSlotEntity(from: '09:00', to: '18:00')],
              ),
            ],
          ),
    ],
  );

  blocTest<OrganizationSettingsBloc, OrganizationSettingsState>(
    'defensive save-time overlap (SAN-573): rejects WITHOUT posting and '
    'WITHOUT touching state.workingHours (no silent dedup), surfacing a '
    'BusinessRuleFailure with the overlap code + conflict metadata',
    build: build,
    seed: () => OrganizationSettingsState(
      status: RequestStatus.success,
      organization: organization,
      workingHours: const [
        WorkingHoursDayEntity(
          day: 'Sunday',
          slots: [WorkingHoursSlotEntity(from: '10:00', to: '16:00')],
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      const OrganizationSettingsWorkingHoursSaved([
        WorkingHoursDayEntity(
          day: 'Saturday',
          slots: [
            WorkingHoursSlotEntity(from: '09:00', to: '14:00'),
            WorkingHoursSlotEntity(from: '13:00', to: '15:00'),
          ],
        ),
      ]),
    ),
    verify: (bloc) {
      expect(bloc.state.saveStatus, RequestStatus.failure);
      expect(bloc.state.saveFailure, isA<BusinessRuleFailure>());
      expect(
        bloc.state.saveFailure!.code,
        workingHoursOverlapFailureCode,
      );
      expect(bloc.state.saveFailure!.metadata?['dayId'], 'Saturday');
      // Existing workingHours state must be preserved (no silent mutation).
      expect(bloc.state.workingHours.length, 1);
      expect(bloc.state.workingHours.single.day, 'Sunday');
      verifyNever(() => updateWorkingHours(any()));
    },
  );
}
