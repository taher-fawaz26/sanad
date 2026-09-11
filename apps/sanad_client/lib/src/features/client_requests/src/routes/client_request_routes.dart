/// Route paths for the client request lifecycle.
///
/// **View and manage only.** A request is created by asking the agent in AI
/// Chat, not by filling in a form here, so there is deliberately no compose or
/// edit route: the client has no manual request-creation surface.
///
/// Registered at the top level rather than inside the AI-chat prototype shell:
/// that shell only exists in debug builds, and a notification tap has to be
/// able to open a request in a shipped app.
abstract final class ClientRequestRoutes {
  ClientRequestRoutes._();

  /// The client's own requests.
  static const String list = '/requests';

  /// One request. `:id` is the request id.
  static const String detailPattern = '/requests/:id';

  /// Builds the detail path for [id].
  ///
  /// Pass [offerId] to focus one negotiation thread — that is where a
  /// `REQUEST_OFFER` notification lands, because an offer thread lives inside
  /// its request rather than on a screen of its own.
  static String detail(String id, {String? offerId}) =>
      offerId == null ? '/requests/$id' : '/requests/$id?offer=$offerId';

  /// The query parameter carrying the offer thread to focus.
  static const String offerQueryParam = 'offer';

  /// Routes that require an authenticated session.
  ///
  /// Only the literal paths: `FeatureRouteContext.protectedRoutes` is matched
  /// by exact string, and the parameterised paths are guarded by the same
  /// redirect through their parent.
  static const Set<String> protectedRoutes = {list};
}
