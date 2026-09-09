/// Route paths for the provider request workspace.
abstract final class ProviderRequestRoutes {
  ProviderRequestRoutes._();

  /// The workspace feed. Also the shell's Requests tab.
  static const String list = '/requests';

  /// One request. `:id` is the request id.
  static const String detailPattern = '/requests/:id';

  /// Builds the detail path for [id].
  ///
  /// [offerId] is accepted so a `REQUEST_OFFER` notification lands on the
  /// request that owns the offer — a provider has exactly one thread per
  /// request, so there is nothing further to disambiguate once here.
  static String detail(String id, {String? offerId}) => '/requests/$id';

  /// Routes that require an authenticated session.
  static const Set<String> protectedRoutes = {list};

  /// Matches the detail route, for the authorization table.
  ///
  /// Deliberately excludes `/requests` itself so the literal rule for the list
  /// can be registered ahead of it — `RouteAuthorizationTable` is
  /// first-match-wins and order is load-bearing.
  static final RegExp detailMatcher = RegExp(r'^/requests/[^/]+$');
}
