import 'package:branches/src/data/datasources/branch_remote_data_source.dart';
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/branches_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class BranchRepositoryImpl implements BranchRepository {
  const BranchRepositoryImpl(this._remoteDataSource);

  final BranchRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, Page<BranchEntity>> getBranches(
    BranchesQuery query,
  ) => _remoteDataSource.getBranches(query).map((dto) => dto.toPage());

  @override
  TaskEither<Failure, BranchEntity> getBranch(GetBranchParams params) =>
      _remoteDataSource.getBranch(params.id).map((dto) => dto.toDomain());

  @override
  TaskEither<Failure, BranchEntity> createBranch(
    CreateBranchParams params,
  ) => _remoteDataSource
      .createBranch(
        CreateBranchRequest(
          branchName: params.branchName,
          branchType: params.branchType,
          branchAddress: params.branchAddress,
          locationPlaceId: params.locationPlaceId,
          branchPhone: params.branchPhone,
          branchManagerId: params.branchManagerId,
          lat: params.lat,
          lng: params.lng,
          radiusKm: params.radiusKm,
          workerIds: params.workerIds,
          googleMapsLink: params.googleMapsLink,
          socialMediaLink: params.socialMediaLink,
          availabilityMode: params.availabilityMode,
          availability: params.availability,
          serviceIds: params.serviceIds,
          servingAreaPlaceIds: params.servingAreaPlaceIds,
        ),
      )
      .map((dto) => dto.toDomain());

  @override
  TaskEither<Failure, BranchEntity> updateBranch(
    UpdateBranchParams params,
  ) => _remoteDataSource
      .updateBranch(
        params.id,
        UpdateBranchRequest(
          branchName: params.branchName,
          branchAddress: params.branchAddress,
          branchPhone: params.branchPhone,
          branchType: params.branchType,
          locationPlaceId: params.locationPlaceId,
          branchManagerId: params.branchManagerId,
          lat: params.lat,
          lng: params.lng,
          radiusKm: params.radiusKm,
          googleMapsLink: params.googleMapsLink,
          socialMediaLink: params.socialMediaLink,
          availabilityMode: params.availabilityMode,
          availability: params.availability,
          serviceIds: params.serviceIds,
          servingAreaPlaceIds: params.servingAreaPlaceIds,
          workerIds: params.workerIds,
        ),
      )
      .map((dto) => dto.toDomain());

  @override
  TaskEither<Failure, BranchEntity> updateBranchStatus(
    UpdateBranchStatusParams params,
  ) => _remoteDataSource
      .updateBranchStatus(params.id, params.statusString)
      .map((dto) => dto.toDomain());

  @override
  TaskEither<Failure, void> deleteBranch(DeleteBranchParams params) =>
      _remoteDataSource.deleteBranch(params.id);

  @override
  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule() =>
      _remoteDataSource.getCompanySchedule();

  @override
  TaskEither<Failure, Page<BranchManagerEntity>> getBranchManagers(
    BranchManagersQuery query,
  ) => _remoteDataSource.getBranchManagers(query).map((dto) => dto.toPage());
}
