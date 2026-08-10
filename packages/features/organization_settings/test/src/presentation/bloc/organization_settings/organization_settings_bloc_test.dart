// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organization_settings/organization_settings.dart';
import 'package:organization_settings/src/domain/entities/business_profile_status.dart';
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

void main() {
  late _MockGetOrganizationSettings getOrganizationSettings;
  late _MockUpdateServiceProviderSettings updateServiceProviderSettings;
  late _MockGetCompletion getCompletion;
  late _MockGetWorkingHours getWorkingHours;
  late _MockUpdateWorkingHours updateWorkingHours;
  late _MockGetCategories getCategories;

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
  });

  setUp(() {
    getOrganizationSettings = _MockGetOrganizationSettings();
    updateServiceProviderSettings = _MockUpdateServiceProviderSettings();
    getCompletion = _MockGetCompletion();
    getWorkingHours = _MockGetWorkingHours();
    updateWorkingHours = _MockUpdateWorkingHours();
    getCategories = _MockGetCategories();

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
  });

  OrganizationSettingsBloc build() => OrganizationSettingsBloc(
    getOrganizationSettings: getOrganizationSettings,
    updateServiceProviderSettings: updateServiceProviderSettings,
    getCompletion: getCompletion,
    getWorkingHours: getWorkingHours,
    updateWorkingHours: updateWorkingHours,
    getCategories: getCategories,
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
}
