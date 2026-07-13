import 'package:branches/src/data/datasources/branch_remote_data_source.dart';
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class BranchRepositoryImpl implements BranchRepository {
  const BranchRepositoryImpl(this._remoteDataSource);

  final BranchRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, PaginatedBranchesEntity> getBranches(
    GetBranchesParams params,
  ) =>
      _remoteDataSource
          .getBranches(page: params.page, limit: params.limit)
          .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, BranchEntity> getBranch(GetBranchParams params) =>
      _remoteDataSource
          .getBranch(params.id)
          .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, BranchEntity> createBranch(
    CreateBranchParams params,
  ) =>
      _remoteDataSource
          .createBranch(
            CreateBranchRequest(
              branchName: params.branchName,
              branchAddress: params.branchAddress,
              city: params.city,
              branchPhone: params.branchPhone,
              branchManagerId: params.branchManagerId,
              lat: params.lat,
              lng: params.lng,
              radiusKm: params.radiusKm,
              googleMapsLink: params.googleMapsLink,
              socialMediaLink: params.socialMediaLink,
              isAvailable: params.isAvailable,
              availabilityMode: params.availabilityMode,
              availability: params.availability,
              serviceIds: params.serviceIds,
            ),
          )
          .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, BranchEntity> updateBranch(
    UpdateBranchParams params,
  ) =>
      _remoteDataSource
          .updateBranch(
            params.id,
            UpdateBranchRequest(
              branchName: params.branchName,
              branchAddress: params.branchAddress,
              city: params.city,
              branchPhone: params.branchPhone,
              branchManagerId: params.branchManagerId,
              lat: params.lat,
              lng: params.lng,
              radiusKm: params.radiusKm,
              googleMapsLink: params.googleMapsLink,
              socialMediaLink: params.socialMediaLink,
              isAvailable: params.isAvailable,
              availabilityMode: params.availabilityMode,
              availability: params.availability,
              serviceIds: params.serviceIds,
            ),
          )
          .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, void> deleteBranch(DeleteBranchParams params) =>
      _remoteDataSource.deleteBranch(params.id);

  @override
  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule() =>
      _remoteDataSource.getCompanySchedule();

  @override
  TaskEither<Failure, List<BranchManagerEntity>> getBranchManagers() =>
      _remoteDataSource.getBranchManagers();
}
