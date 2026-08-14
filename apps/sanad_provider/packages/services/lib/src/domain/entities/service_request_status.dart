/// `ServiceRequest.status` — `all` is a filter-only value, never returned
/// by the backend.
enum ServiceRequestStatus {
  underReview,
  approved,
  rejected,
  all
  ;

  static ServiceRequestStatus fromApi(String value) => switch (value) {
    'underreview' => ServiceRequestStatus.underReview,
    'approved' => ServiceRequestStatus.approved,
    'rejected' => ServiceRequestStatus.rejected,
    _ => ServiceRequestStatus.all,
  };

  String toApi() => switch (this) {
    ServiceRequestStatus.underReview => 'underreview',
    ServiceRequestStatus.approved => 'approved',
    ServiceRequestStatus.rejected => 'rejected',
    ServiceRequestStatus.all => 'all',
  };
}
