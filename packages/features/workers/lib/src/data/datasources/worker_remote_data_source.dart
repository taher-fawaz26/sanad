import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/data/models/worker_dto.dart';

abstract interface class WorkerRemoteDataSource {
  TaskEither<Failure, List<WorkerDto>> getWorkers();
}

/// Static workers returned until the API is wired.
const _kStaticWorkers = <WorkerDto>[
  WorkerDto(
    id: 'wrk-mohamed-ali',
    fullName: 'Mohamed Ali',
    role: 'Cleaner',
    initials: 'MA',
  ),
  WorkerDto(
    id: 'wrk-fatima-ahmed',
    fullName: 'Fatima Ahmed',
    role: 'Cook',
    initials: 'FA',
  ),
  WorkerDto(
    id: 'wrk-khaled-mahmoud',
    fullName: 'Khaled Mahmoud',
    role: 'Security Guard',
    initials: 'KM',
  ),
  WorkerDto(
    id: 'wrk-noura-salem',
    fullName: 'Noura Salem',
    role: 'Nurse',
    initials: 'NS',
  ),
  WorkerDto(
    id: 'wrk-omar-hassan',
    fullName: 'Omar Hassan',
    role: 'Maintenance Technician',
    initials: 'OH',
  ),
  WorkerDto(
    id: 'wrk-sara-youssef',
    fullName: 'Sara Youssef',
    role: 'Receptionist',
    initials: 'SY',
  ),
];

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  const WorkerRemoteDataSourceImpl();

  @override
  TaskEither<Failure, List<WorkerDto>> getWorkers() =>
      TaskEither.right(_kStaticWorkers);

  // Future API integration:
  // _apiClient.request<List<WorkerDto>>(
  //   path: WorkerApiPaths.workers,
  //   method: RequestMethod.get,
  //   parser: (data) => (data as List<dynamic>)
  //       .map((e) => WorkerDto.fromJson(e as Map<String, dynamic>))
  //       .toList(),
  // );
}
