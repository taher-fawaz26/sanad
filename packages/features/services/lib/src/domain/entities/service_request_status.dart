/// `ServiceRequestResponseDto.status` — exactly the three backend values.
enum ServiceRequestStatus {
  pending,
  approved,
  rejected
  ;

  static ServiceRequestStatus fromApi(String value) => switch (value) {
    'PENDING' => ServiceRequestStatus.pending,
    'APPROVED' => ServiceRequestStatus.approved,
    'REJECTED' => ServiceRequestStatus.rejected,
    _ => ServiceRequestStatus.pending,
  };

  String toApi() => switch (this) {
    ServiceRequestStatus.pending => 'PENDING',
    ServiceRequestStatus.approved => 'APPROVED',
    ServiceRequestStatus.rejected => 'REJECTED',
  };
}
