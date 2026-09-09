/// Route paths for the client request lifecycle.
///
/// Registered at the top level rather than inside the AI-chat prototype shell:
/// that shell only exists in debug builds, and a notification tap has to be
/// able to open a request in a shipped app.
abstract final class ClientRequestRoutes {
  ClientRequestRoutes._();

  /// The client's own requests.
  static const String list = '/requests';

  /// The composer, creating a new draft.
  static const String compose = '/requests/new';

  /// One request. `:id` is the request id.
  static const String detailPattern = '/requests/:id';

  /// Editing an existing request in the composer.
  static const String editPattern = '/requests/:id/edit';

  /// Builds the detail path for [id].
  ///
  /// Pass [offerId] to focus one negotiation thread — that is where a
  /// `REQUEST_OFFER` notification lands, because an offer thread lives inside
  /// its request rather than on a screen of its own.
  static String detail(String id, {String? offerId}) =>
      offerId == null ? '/requests/$id' : '/requests/$id?offer=$offerId';

  /// Builds the edit path for [id].
  static String edit(String id) => '/requests/$id/edit';

  /// The query parameter carrying the offer thread to focus.
  static const String offerQueryParam = 'offer';

  /// Routes that require an authenticated session.
  ///
  /// Only the literal paths: `FeatureRouteContext.protectedRoutes` is matched
  /// by exact string, and the parameterised paths are guarded by the same
  /// redirect through their parent.
  static const Set<String> protectedRoutes = {list, compose};
}
