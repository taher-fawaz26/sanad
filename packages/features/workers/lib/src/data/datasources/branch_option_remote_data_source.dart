import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:workers/src/domain/entities/branch_option_entity.dart';

/// Fetches a lightweight id/name branch list for the Add/Edit Member branch
/// picker, hitting the same verified `branches` endpoint the branches
/// package uses, without depending on that package's full domain layer.
abstract interface class BranchOptionRemoteDataSource {
  TaskEither<Failure, List<BranchOptionEntity>> getBranchOptions({
    String? search,
  });
}

class BranchOptionRemoteDataSourceImpl implements BranchOptionRemoteDataSource {
  const BranchOptionRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<BranchOptionEntity>> getBranchOptions({
    String? search,
  }) => _apiClient.request<List<BranchOptionEntity>>(
    path: 'branches',
    method: RequestMethod.get,
    query: {
      'page': 1,
      'limit': 50,
      if (search != null && search.isNotEmpty) 'search': search,
    },
    parser: (data) => ((data as Map<String, dynamic>)['data'] as List<dynamic>)
        .map(
          (e) => BranchOptionEntity(
            id: (e as Map<String, dynamic>)['id'] as String,
            name: e['name'] as String? ?? '',
          ),
        )
        .toList(),
  );
}
