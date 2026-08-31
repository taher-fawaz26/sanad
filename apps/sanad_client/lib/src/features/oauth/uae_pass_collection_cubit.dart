import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collected_details.dart';

/// Drives the row-by-row reveal on "We collect data from UAE PASS"
/// (`7020:28255`): each field starts [RequestStatus.loading] and flips to
/// [RequestStatus.success] in turn, matching Figma's loading → partial →
/// completed staging (see task spec §8).
///
/// UI-only for this phase — see `OAuthUaePassPage`'s class doc for the
/// feature-wide boundary. There is no real UAE PASS data-collection response
/// to drive this yet, so the reveal is paced by fixed local timers rather
/// than any backend call; swapping in the real integration only means
/// replacing [_stageCollection] with the real response handling, the state
/// shape and the two screens that read it stay unchanged.
class UaePassCollectionCubit extends Cubit<UaePassCollectionState> {
  /// Creates a [UaePassCollectionCubit] and starts the staged reveal.
  UaePassCollectionCubit({UaePassCollectedDetails? details})
    : super(
        UaePassCollectionState.initial(
          details ?? UaePassCollectedDetails.placeholder(),
        ),
      ) {
    _stageCollection();
  }

  Timer? _fullNameTimer;
  Timer? _verifiedIdentityTimer;
  Timer? _mobileNumberTimer;

  void _stageCollection() {
    _fullNameTimer = Timer(const Duration(milliseconds: 600), () {
      if (!isClosed) {
        emit(state.copyWith(fullNameStatus: RequestStatus.success));
      }
    });
    _verifiedIdentityTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!isClosed) {
        emit(state.copyWith(verifiedIdentityStatus: RequestStatus.success));
      }
    });
    _mobileNumberTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!isClosed) {
        emit(state.copyWith(mobileNumberStatus: RequestStatus.success));
      }
    });
  }

  @override
  Future<void> close() {
    _fullNameTimer?.cancel();
    _verifiedIdentityTimer?.cancel();
    _mobileNumberTimer?.cancel();
    return super.close();
  }
}

/// State for [UaePassCollectionCubit] — one [RequestStatus] per field plus
/// the (placeholder, until real data exists) values to display.
class UaePassCollectionState extends Equatable {
  /// Creates a [UaePassCollectionState].
  const UaePassCollectionState({
    required this.fullNameStatus,
    required this.verifiedIdentityStatus,
    required this.mobileNumberStatus,
    required this.details,
  });

  /// All three fields start [RequestStatus.loading].
  factory UaePassCollectionState.initial(UaePassCollectedDetails details) =>
      UaePassCollectionState(
        fullNameStatus: RequestStatus.loading,
        verifiedIdentityStatus: RequestStatus.loading,
        mobileNumberStatus: RequestStatus.loading,
        details: details,
      );

  /// Full-name row status.
  final RequestStatus fullNameStatus;

  /// Verified-identity row status.
  final RequestStatus verifiedIdentityStatus;

  /// Mobile-number row status.
  final RequestStatus mobileNumberStatus;

  /// Values to display once each row completes.
  final UaePassCollectedDetails details;

  int get _completedCount => [
    fullNameStatus,
    verifiedIdentityStatus,
    mobileNumberStatus,
  ].where((status) => status == RequestStatus.success).length;

  /// `0.0`–`1.0` fraction of fields received, for the progress bar.
  double get progress => _completedCount / 3;

  /// Whether every field has arrived — enables the "continue to Sanad"
  /// button.
  bool get isComplete => _completedCount == 3;

  /// Returns a copy with the given field(s) replaced.
  UaePassCollectionState copyWith({
    RequestStatus? fullNameStatus,
    RequestStatus? verifiedIdentityStatus,
    RequestStatus? mobileNumberStatus,
  }) {
    return UaePassCollectionState(
      fullNameStatus: fullNameStatus ?? this.fullNameStatus,
      verifiedIdentityStatus:
          verifiedIdentityStatus ?? this.verifiedIdentityStatus,
      mobileNumberStatus: mobileNumberStatus ?? this.mobileNumberStatus,
      details: details,
    );
  }

  @override
  List<Object?> get props => [
    fullNameStatus,
    verifiedIdentityStatus,
    mobileNumberStatus,
    details,
  ];
}
