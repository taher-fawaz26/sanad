import 'package:core/core.dart';
import 'package:network/src/client/error_mapper.dart';

/// Canonical failure mapper — alias for [ErrorMapper].
///
/// All data-layer errors must flow through this class.
/// See `docs/API_GUIDE.md` for the full mapping table.
abstract final class FailureMapper {
  FailureMapper._();

  /// Maps any thrown object to a domain [Failure].
  static Failure map(Object error) => ErrorMapper.mapError(error);
}
