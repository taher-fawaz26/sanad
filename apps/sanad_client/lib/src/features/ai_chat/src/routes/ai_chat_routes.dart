/// Route paths contributed by the AI chat feature.
abstract final class AiChatRoutes {
  /// Namespaced under `/dev` and registered only in non-release builds, so the
  /// prototype cannot appear in a production flow.
  static const chat = '/dev/ai-chat';

  /// The live-voice surface. A separate route because live voice is a separate
  /// subsystem with its own bloc, its own lifecycle and its own screen — and
  /// because leaving it must release the microphone, which a nested sheet on
  /// the chat route would not guarantee.
  static const voice = '/dev/ai-chat/voice';

  /// Structural placeholder — a `StatefulShellRoute` branch alongside [chat].
  /// See `RequestsPage`.
  static const requests = '/dev/ai-chat/requests';

  /// Structural placeholder — a `StatefulShellRoute` branch alongside [chat].
  /// See `MyLifePage`.
  static const myLife = '/dev/ai-chat/my-life';

  /// Structural placeholder, reached by push (not a shell branch) from the
  /// Home header. See `HistoryPage`.
  static const history = '/dev/ai-chat/history';

  /// Not added to `ClientRoutes.protected`: the prototype has no session
  /// dependency, and gating it behind auth would only make it harder to demo.
  static const Set<String> protectedRoutes = {};
}
