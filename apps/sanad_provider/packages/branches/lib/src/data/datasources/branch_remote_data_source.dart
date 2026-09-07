import 'package:branches/src/data/endpoints/branch_api_paths.dart';
import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/data/models/branch_dto.dart';
import 'package:branches/src/data/models/branch_list_response_dto.dart';
import 'package:branches/src/data/models/manager_list_response_dto.dart';
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:branches/src/domain/usecases/branches_query.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

abstract interface class BranchRemoteDataSource {
  TaskEither<Failure, BranchListResponseDto> getBranches(BranchesQuery query);

  TaskEither<Failure, BranchDto> getBranch(String id);

  TaskEither<Failure, BranchDto> createBranch(CreateBranchRequest request);

  TaskEither<Failure, BranchDto> updateBranch(
    String id,
    UpdateBranchRequest request,
  );

  TaskEither<Failure, BranchDto> updateBranchStatus(
    String id,
    String status,
  );

  TaskEither<Failure, void> deleteBranch(String id);

  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule();

  TaskEither<Failure, ManagerListResponseDto> getBranchManagers(
    BranchManagersQuery query,
  );
}

class BranchRemoteDataSourceImpl implements BranchRemoteDataSource {
  const BranchRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, BranchListResponseDto> getBranches(
    BranchesQuery query,
  ) => _apiClient.request<BranchListResponseDto>(
    path: BranchApiPaths.branches,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) =>
        BranchListResponseDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, BranchDto> getBranch(String id) =>
      _apiClient.request<BranchDto>(
        path: BranchApiPaths.branch(id),
        method: RequestMethod.get,
        parser: (data) => BranchDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, BranchDto> createBranch(
    CreateBranchRequest request,
  ) => _apiClient.request<BranchDto>(
    path: BranchApiPaths.branches,
    method: RequestMethod.post,
    body: request.toMap(),
    parser: (data) => BranchDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, BranchDto> updateBranch(
    String id,
    UpdateBranchRequest request,
  ) => _apiClient.request<BranchDto>(
    path: BranchApiPaths.branch(id),
    method: RequestMethod.patch,
    body: request.toMap(),
    parser: (data) => BranchDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, BranchDto> updateBranchStatus(
    String id,
    String status,
  ) => _apiClient.request<BranchDto>(
    path: BranchApiPaths.branchStatus(id),
    method: RequestMethod.patch,
    body: {'status': status},
    parser: (data) => BranchDto.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, void> deleteBranch(String id) => _apiClient.request<void>(
    path: BranchApiPaths.branch(id),
    method: RequestMethod.delete,
    parser: (_) {},
  );

  @override
  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule() =>
      _apiClient.request<List<BranchAvailabilityEntity>>(
        path: BranchApiPaths.companySchedule,
        method: RequestMethod.get,
        parser: (data) {
          final map = data as Map<String, dynamic>;
          final list = map['availability'] as List<dynamic>?;
          if (list == null) return [];
          // Day codes are normalized to the canonical all-caps form inside
          // `BranchAvailabilityDto.toDomain()` — the single boundary shared
          // with the branch payload's own availability (SAN-780).
          return list
              .map(
                (e) => BranchAvailabilityDto.fromJson(
                  e as Map<String, dynamic>,
                ).toDomain(),
              )
              .toList();
        },
      );

  @override
  TaskEither<Failure, ManagerListResponseDto> getBranchManagers(
    BranchManagersQuery query,
  ) => _apiClient.request<ManagerListResponseDto>(
    path: BranchApiPaths.branchManagers,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) =>
        ManagerListResponseDto.fromJson(data as Map<String, dynamic>),
  );
}
