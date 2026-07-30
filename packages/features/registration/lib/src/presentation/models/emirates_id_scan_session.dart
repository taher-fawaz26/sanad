import 'package:asset_picker/asset_picker.dart';
import 'package:equatable/equatable.dart';

/// Which Emirates ID side is being (re)captured in a partial scan flow.
enum EmiratesIdScanSide { front, back }

/// Where the scan flow was launched from — controls review navigation.
enum EmiratesIdScanLaunch { identity, review }

/// Local front/back captures carried through the Emirates ID scan flow.
class EmiratesIdScanSession extends Equatable {
  const EmiratesIdScanSession({this.front, this.back});

  final PickedAsset? front;
  final PickedAsset? back;

  bool get hasFront => front != null;
  bool get hasBack => back != null;
  bool get isComplete => hasFront && hasBack;

  EmiratesIdScanSession copyWith({
    Object? front = _sentinel,
    Object? back = _sentinel,
  }) =>
      EmiratesIdScanSession(
        front: identical(front, _sentinel)
            ? this.front
            : front as PickedAsset?,
        back: identical(back, _sentinel)
            ? this.back
            : back as PickedAsset?,
      );

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [front, back];
}
