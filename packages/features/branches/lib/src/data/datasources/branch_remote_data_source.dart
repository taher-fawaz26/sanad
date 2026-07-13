import 'package:branches/src/data/endpoints/branch_api_paths.dart';
import 'package:branches/src/data/models/branch_dto.dart';
import 'package:branches/src/data/models/branch_list_response_dto.dart';
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
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

  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule();

  TaskEither<Failure, List<BranchManagerEntity>> getBranchManagers();
}

/// Static company schedule returned until the API is wired.
const _kStaticCompanySchedule = <BranchAvailabilityEntity>[
  BranchAvailabilityEntity(
    day: 'SATURDAY',
    slots: [BranchTimeSlotEntity(from: '09:00', to: '18:00')],
  ),
  BranchAvailabilityEntity(
    day: 'SUNDAY',
    slots: [BranchTimeSlotEntity(from: '10:00', to: '16:00')],
  ),
  BranchAvailabilityEntity(
    day: 'MONDAY',
    slots: [BranchTimeSlotEntity(from: '08:00', to: '17:00')],
  ),
];

/// Static branch managers returned until the workers API is wired.
const _kStaticBranchManagers = <BranchManagerEntity>[
  BranchManagerEntity(
    id: 'f490f1ee-6c54-4b01-90e6-d701748f0851',
    fullName: 'Ahmed Hassan',
    initials: 'AH',
  ),
  BranchManagerEntity(
    id: 'a12b3c4d-5e6f-7890-abcd-ef1234567890',
    fullName: 'Sara Al Mansouri',
    initials: 'SM',
  ),
  BranchManagerEntity(
    id: 'b23c4d5e-6f70-8901-bcde-f12345678901',
    fullName: 'Omar Khalid',
    initials: 'OK',
  ),
];

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

  @override
  TaskEither<Failure, List<BranchAvailabilityEntity>> getCompanySchedule() =>
      TaskEither.right(_kStaticCompanySchedule);

  @override
  TaskEither<Failure, List<BranchManagerEntity>> getBranchManagers() =>
      TaskEither.right(_kStaticBranchManagers);
}
