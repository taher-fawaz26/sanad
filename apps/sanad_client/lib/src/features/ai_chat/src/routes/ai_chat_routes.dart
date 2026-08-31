/// Route paths contributed by the AI chat feature.
abstract final class AiChatRoutes {
  /// Namespaced under `/dev` and registered only in non-release builds, so the
  /// prototype cannot appear in a production flow.
  static const chat = '/dev/ai-chat';

  /// Not added to `ClientRoutes.protected`: the prototype has no session
  /// dependency, and gating it behind auth would only make it harder to demo.
  static const Set<String> protectedRoutes = {};
}
