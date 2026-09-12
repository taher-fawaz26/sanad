/// Route paths contributed by the AI chat feature.
///
/// These are the client app's real, shipped surfaces — Chat and its sibling
/// shell branches. Their registration is decided by
/// `AppConfig.enableAiChatShell` (see `AiChatModule.routes`): every
/// non-production build exposes them, a production binary tree-shakes them out.
/// Whether the chat behind them talks to the agent or to the deterministic
/// local journey is a separate axis (`AppConfig.useMockBackend`). Nothing here
/// is `/dev`-namespaced or demo-only — from the user's perspective this is the
/// normal app.
abstract final class AiChatRoutes {
  /// The chat home surface.
  ///
  /// There is exactly one chat route and it takes no query parameters. Whether
  /// this visit talks to the agent or to the deterministic local journey is a
  /// build-time decision — see `AppConfig.useMockBackend` — so the same URL
  /// demonstrates the product and ships it.
  static const chat = '/ai-chat';

  /// The live-voice surface. A separate route because live voice is a separate
  /// subsystem with its own bloc, its own lifecycle and its own screen — and
  /// because leaving it must release the microphone, which a nested sheet on
  /// the chat route would not guarantee.
  static const voice = '/ai-chat/voice';

  /// The client's own requests — a `StatefulShellRoute` branch alongside
  /// [chat]. See `ClientRequestsPage`.
  ///
  /// Namespaced under the shell (distinct from the top-level
  /// `ClientRequestRoutes.list` `/requests`, which renders the same page with
  /// its own nav bar). Whether the rows come from the API or from fixtures is
  /// decided in DI by `AppConfig.useMockBackend`, not by the URL, so the
  /// presenter opens the normal screen either way.
  static const requests = '/ai-chat/requests';

  /// Structural placeholder — a `StatefulShellRoute` branch alongside [chat].
  /// See `MyLifePage`.
  static const myLife = '/ai-chat/my-life';

  /// Reached by push (not a shell branch) from the Home header. See
  /// `HistoryPage`.
  static const history = '/ai-chat/history';

  /// Not added to `ClientRoutes.protected`: the chat surface has no session
  /// dependency of its own; access is gated by the `/home` redirect that leads
  /// here, which is protected.
  static const Set<String> protectedRoutes = {};
}
