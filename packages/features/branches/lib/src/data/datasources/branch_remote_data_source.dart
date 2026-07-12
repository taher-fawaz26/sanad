import 'package:branches/src/data/endpoints/branch_api_paths.dart';
import 'package:branches/src/data/models/branch_dto.dart';
import 'package:branches/src/data/models/branch_list_response_dto.dart';
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
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

  TaskEither<Failure, void> deleteBranch(String id);
}

class BranchRemoteDataSourceImpl implements BranchRemoteDataSource {
  const BranchRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, BranchListResponseDto> getBranches({
    required int page,
    required int limit,
  }) =>
      _apiClient.request<BranchListResponseDto>(
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
        parser: (data) =>
            BranchDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, BranchDto> createBranch(
    CreateBranchRequest request,
  ) =>
      _apiClient.request<BranchDto>(
        path: BranchApiPaths.branches,
        method: RequestMethod.post,
        body: request.toMap(),
        parser: (data) =>
            BranchDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, BranchDto> updateBranch(
    String id,
    UpdateBranchRequest request,
  ) =>
      _apiClient.request<BranchDto>(
        path: BranchApiPaths.branch(id),
        method: RequestMethod.patch,
        body: request.toMap(),
        parser: (data) =>
            BranchDto.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> deleteBranch(String id) =>
      _apiClient.request<void>(
        path: BranchApiPaths.branch(id),
        method: RequestMethod.delete,
        parser: (_) {},
      );
}
