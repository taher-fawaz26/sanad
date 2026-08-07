import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organization_settings/src/domain/entities/organization_settings_entity.dart';
import 'package:organization_settings/src/domain/usecases/get_organization_settings_usecase.dart';

part 'organization_settings_event.dart';
part 'organization_settings_state.dart';

/// Single source of truth for the entire Organization Settings feature.
///
/// Loads the organization's full settings profile via
/// `GET /service-provider/me` and keeps one root
/// [OrganizationSettingsEntity] in state — every section on the general
/// settings page reads from it instead of independent models or mocked
/// state.
class OrganizationSettingsBloc
    extends Bloc<OrganizationSettingsEvent, OrganizationSettingsState> {
  OrganizationSettingsBloc({
    required GetOrganizationSettingsUseCase getOrganizationSettings,
  }) : _getOrganizationSettings = getOrganizationSettings,
       super(const OrganizationSettingsState()) {
    on<OrganizationSettingsLoaded>(_onLoaded);
    on<OrganizationSettingsRefreshed>(_onLoaded);
  }

  final GetOrganizationSettingsUseCase _getOrganizationSettings;

  Future<void> _onLoaded(
    OrganizationSettingsEvent event,
    Emitter<OrganizationSettingsState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));

    final result = await _getOrganizationSettings(const NoParams()).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (organization) => emit(
        state.copyWith(
          status: RequestStatus.success,
          organization: organization,
        ),
      ),
    );
  }
}
