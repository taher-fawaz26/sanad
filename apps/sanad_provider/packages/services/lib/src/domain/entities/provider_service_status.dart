/// Status of a provider's offered service. `all` is a filter-only value —
/// it is never returned by the backend, only sent as a query parameter.
enum ProviderServiceStatus {
  active,
  inactive,
  all
  ;

  static ProviderServiceStatus fromApi(String value) => switch (value) {
    'active' => ProviderServiceStatus.active,
    'inactive' => ProviderServiceStatus.inactive,
    _ => ProviderServiceStatus.all,
  };

  String toApi() => switch (this) {
    ProviderServiceStatus.active => 'active',
    ProviderServiceStatus.inactive => 'inactive',
    ProviderServiceStatus.all => 'all',
  };
}
