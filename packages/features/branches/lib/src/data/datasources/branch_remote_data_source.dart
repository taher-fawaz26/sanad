import 'package:branches/src/data/endpoints/branch_api_paths.dart';
import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/data/models/branch_dto.dart';
import 'package:branches/src/data/models/branch_list_response_dto.dart';
import 'package:branches/src/data/models/manager_list_response_dto.dart';
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/paginated_managers_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

abstract interface class BranchRemoteDataSource {
  TaskEither<Failure, BranchListResponseDto> getBranches({
    required int page,
    required int limit,
  });

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

  TaskEither<Failure, PaginatedManagersEntity> getBranchManagers(
    GetBranchManagersParams params,
  );
}

class BranchRemoteDataSourceImpl implements BranchRemoteDataSource {
  const BranchRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, BranchListResponseDto> getBranches({
    required int page,
    required int limit,
  }) => _apiClient.request<BranchListResponseDto>(
    path: BranchApiPaths.branches,
    method: RequestMethod.get,
    query: {'page': page, 'limit': limit},
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
        parser: (data) => (data as List<dynamic>)
            .map(
              (e) => BranchAvailabilityDto.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList(),
      );

  @override
  TaskEither<Failure, PaginatedManagersEntity> getBranchManagers(
    GetBranchManagersParams params,
  ) {
    final query = <String, dynamic>{
      'type': 'manager',
      'page': params.page,
      'limit': params.limit,
    };
    if (params.query != null && params.query!.isNotEmpty) {
      query['search'] = params.query;
    }
    return _apiClient.request<PaginatedManagersEntity>(
      path: BranchApiPaths.branchManagers,
      method: RequestMethod.get,
      query: query,
      parser: (data) => ManagerListResponseDto.fromJson(
        data as Map<String, dynamic>,
      ).toDomain(),
    );
  }
}
