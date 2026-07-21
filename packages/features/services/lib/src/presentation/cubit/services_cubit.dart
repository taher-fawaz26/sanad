import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/domain/entities/service_entity.dart';
import 'package:services/src/domain/usecases/get_services_usecase.dart';

enum ServicesStatus { initial, loading, success, failure }

/// State for the service picker: load status, the loaded services, and any
/// failure. Selection/search are UI-only concerns kept in the widget.
class ServicesState extends Equatable {
  const ServicesState({
    this.status = ServicesStatus.initial,
    this.services = const <ServiceEntity>[],
    this.failure,
  });

  final ServicesStatus status;
  final List<ServiceEntity> services;
  final Failure? failure;

  bool get isLoading => status == ServicesStatus.loading;
  bool get hasError => status == ServicesStatus.failure;

  ServicesState copyWith({
    ServicesStatus? status,
    List<ServiceEntity>? services,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      ServicesState(
        status: status ?? this.status,
        services: services ?? this.services,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, services, failure];
}

/// Loads provider services for the picker. Brings the services feature onto
/// the same bloc-based flow as every other feature (EH-S3-01) instead of
/// calling the use case directly from the widget.
class ServicesCubit extends Cubit<ServicesState> {
  ServicesCubit(this._getServices) : super(const ServicesState());

  final GetServicesUseCase _getServices;

  Future<void> load() async {
    emit(state.copyWith(status: ServicesStatus.loading, clearFailure: true));
    final result = await _getServices(const NoParams()).run();
    result.fold(
      (failure) => emit(
        state.copyWith(status: ServicesStatus.failure, failure: failure),
      ),
      (services) => emit(
        ServicesState(status: ServicesStatus.success, services: services),
      ),
    );
  }
}
