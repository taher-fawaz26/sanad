part of 'request_details_bloc.dart';

sealed class RequestDetailsEvent extends Equatable {
  const RequestDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches (or re-fetches, on retry) the full detail for `state.request.id`.
final class RequestDetailsFetchRequested extends RequestDetailsEvent {
  const RequestDetailsFetchRequested();
}
