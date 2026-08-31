# AI Chat — Architecture

How the SANAD AI chat prototype is put together, and why the seams are where
they are. Describes the code as it exists today.

Related: [`PROTOCOL_V1.md`](PROTOCOL_V1.md) (the wire contract),
[`AI_CONTRACT.md`](AI_CONTRACT.md) (agent-facing rules),
[`../features/ai-chat.md`](../features/ai-chat.md) (feature walkthrough),
[`../adr/0009-ai-chat-ui-protocol.md`](../adr/0009-ai-chat-ui-protocol.md)
(why this shape and not an off-the-shelf one).

---

## 1. Layers

```text
        MockAiChatEventSource            ← prototype transport (local, scripted)
                 │  implements AiChatEventSource
                 ▼
   apps/sanad_client/lib/src/features/ai_chat/          (app-local, tier 7)
     domain/        AiChatMessage · AiChatEventSource
     data/          MockAiChatEventSource · mock_scenarios
     presentation/  AiChatBloc + ActiveStreamController
                    AiChatScreen → AiChatPage → AiChatBubble/Composer
                    ai_chat_action_handlers
     ai_chat_config.dart   URL policy · supported actions · validator factory
                 │
                 │  AiUiDocument (already parsed and validated)
                 ▼
   packages/ai_ui_renderer                              (tier 3, Flutter)
     AiUiHost/AiUiSurface → AiUiRendererRegistry → AiNodeRenderer → App* widgets
     AiActionRegistry → AiActionHandler → app code
     AiAssetResolver · AiIconResolver · AiUiTokens · AiUiFormatters
     AiUiDiagnosticsSink
                 │
                 ▼
   packages/ai_ui_protocol                              (tier 0, PURE DART)
     AiUiCodec · AiUiValidator · AiUiLimits · AiUiUrlPolicy
     AiUiDocument · AiUiNode (sealed) · AiUiAction · AiUiDiagnostic
     AiChatEvent (sealed) · AiChatEventCodec
```

Tiers are enforced by [`dep_rules.yaml`](../../dep_rules.yaml) and
`melos run validate:deps --strict`.

---

## 2. The load-bearing boundary

`ai_ui_protocol` declares **no dependency on Flutter**. Not by convention — by
`pubspec.yaml`. Its only dependencies are `equatable` and `meta`.

A payload parsed there therefore *cannot* reference a `Widget`, a `Color`, an
`IconData`, a route or the network, because none of those types are reachable
from the package. "AI output is untrusted data, not code" is a property of the
dependency graph rather than a rule someone has to remember.

Everything that can *act* on a payload lives in `ai_ui_renderer`, which is small
and auditable. The question "what can an AI payload reach?" has one answer, in
one place.

---

## 3. Transport seam

```dart
abstract class AiChatEventSource {
  Stream<AiChatEvent> get events;
  Future<void> send(String text);
  Future<void> dispose();
}
```

Three members. `MockAiChatEventSource` implements it by replaying scripted
events with realistic pacing; a WebSocket implementation is a second class with
the same three members. Nothing above the interface knows the difference — the
bloc, the renderer and the protocol are all transport-agnostic.

The envelope model and its codec live in `ai_ui_protocol`, not in the feature,
precisely so a future socket source and a second app can share them.

---

## 4. Parse once, at ingestion

`AiChatBloc` validates a `ui` event the moment it arrives and stores the
resulting `AiUiDocument` on the message. No widget ever sees raw JSON.

Consequences:

- no `build()` pays for decoding, on any frame;
- a malformed payload is a *state* the UI renders, never an exception it must
  survive;
- renderers are total functions over validated data, so they contain no
  defensive parsing.

## 5. Validator and renderer share their allowlists

```dart
AiChatConfig.validator(keepUnsupportedNodes: !kReleaseMode)
// urlPolicy       : AiUiUrlPolicy.denyAll
// supportedActions: AiChatConfig.supportedActions   (6 actions)
// knownAssetIds   : AiAssetResolver.defaults().publishedIds
```

The action set the validator enforces is the same set the action registry
implements, and the asset ids it accepts are the ones the resolver can resolve.
That is what makes "a button that renders always does something" true rather
than hopeful: an action with no handler is dropped *before* a widget exists.

A test asserts the registry's keys equal `AiChatConfig.supportedActions`.

In `ai_ui_renderer`, `validatorFor(environment)` does the same derivation for
any other host.

---

## 6. Streaming without rebuilding the conversation

The requirement: a token must not rebuild the message list.

```text
text_delta ──► AiChatBloc ──► ActiveStreamController (ValueNotifier<String>)
                   │                     │
              (no emit)          ValueListenableBuilder
                                          │
                                  the active bubble only
```

`AiChatBloc` emits a list-level state only when a message is **added,
completed, or fails**. `text_delta` calls `activeStream.append(delta)` and
returns without emitting. Only the streaming bubble listens to the notifier, so
exactly one widget rebuilds per token.

Supporting details: `ListView.builder(reverse: true)`, `ValueKey(message.id)`,
a `RepaintBoundary` per row, `Equatable` messages, and a `buildWhen` that only
fires on list-shaped changes.

Two tests pin this: one asserts 0 bloc states across a burst of deltas
(`ai_chat_bloc_test.dart`), one asserts the streaming bubble updates while a
completed sibling is untouched (`ai_chat_widget_test.dart`).

---

## 7. Renderer registry

```dart
abstract class AiNodeRenderer<T extends AiUiNode> {
  Widget render(BuildContext context, T node, AiUiRenderScope scope);
  Widget build(BuildContext context, AiUiNode node, AiUiRenderScope scope);
}
```

`AiUiRendererRegistry` maps `AiUiNodeType` → renderer, plus a separate
`fallbackRenderer` slot for `AiUiUnsupportedNode` (whose `type` is `null` by
definition and so cannot be keyed).

A registry rather than a `switch` over the sealed hierarchy is a deliberate
trade: we give up compile-time exhaustiveness to gain the ability to override
one node type without editing a central file. A test restores the lost safety by
asserting every protocol node type has a default renderer.

`AiUiRenderScope` carries the registry, action dispatcher, resolvers,
diagnostics sink and depth **down the tree by constructor**. `AiUiSurface` reads
the `AiUiHost` environment exactly once per surface, so drawing a 100-node tree
does no per-node ancestor lookups.

## 8. Design-system mapping

`AiUiTokens` is the only place protocol vocabulary becomes SANAD tokens:
`tone` → `context.appColors` roles, `style`/`emphasis` → `context.appTypography`,
`gap`/`spacing` → `AppSpacing`, `variant`/`intent`/`size` → the real
`AppButton*` enums.

Nodes render as `AppButton`, `AppChip`, `AppSectionCard`, `AppEntityListItem`,
`AppStatusBadge`, `AppDivider`, `AppProgressBar`, `AppLoadingIndicator`,
`AppSvgPicture` and `FaIcon`. There is no parallel theme.

`AiUiFormatters` renders structured values (`price`, `startsAt`,
`distanceMeters`, `ratingValue`) in the device locale via `intl`, using the
repo's explicit 12-hour `DateFormat('h:mm a')` convention.

`ai_ui_renderer` does **not** depend on `localization`. The few display strings
it needs come in through `AiUiStrings`, injected by the host, so a presentation
library does not force a translation bootstrap on every consumer.

---

## 9. Action architecture

```text
AiUiAction ──► AiActionRegistry (Map<AiUiActionType, AiActionHandler>) ──► app code
```

Built at DI time. No string-to-method dispatch, no reflection, no eval. The
registry's key set is handed to the validator (§5), so an unregistered action is
unreachable.

The client registers six handlers. `open_url` and `open_route` are deliberately
absent: there is no symbolic route map yet, and registering `open_url` would let
the agent send the user off-app.

Prototype handlers for the four `open_*` actions surface the resolved intent as
a snackbar, because the destination screens do not exist in `sanad_client` yet.
Replacing each with `context.push(ClientRoutes.…)` is a one-line change.

---

## 10. Security model

| Threat | Mitigation |
|---|---|
| Code execution | Protocol is pure Dart data. No eval, no reflection, no widget DSL. |
| Arbitrary navigation | `open_route` takes a symbolic key, and is not implemented anyway. Raw paths are not representable. |
| Arbitrary network | Images are `assetId`-only in v1; `image.url` is rejected for every host. `open_url` is gated by `AiUiUrlPolicy` **and** unimplemented. |
| Token / storage access | The protocol and renderer have no `storage`, `network` or `auth` dependency — by pubspec, not by policy. |
| Destructive actions | Six allowlisted actions; each handler is app code that owns its own authorization. |
| Resource exhaustion | `AiUiLimits` enforced before any widget is built. |
| Crash-as-DoS | Total parse/validate; renderers operate on validated types; per-subtree try/catch. |
| PII in logs | Diagnostics carry code + path + node type only, capped at 120 chars — never payload prose. |

---

## 11. Diagnostics

`AiUiDiagnosticsSink` receives everything the client refused to render.
`LoggingAiUiDiagnosticsSink` routes to `appLogger`, and renderer failures
additionally to `ErrorReporter.report(..., fatal: false)` — the seam an app
swaps for a crash backend at bootstrap.

Known prototype limitation: `appLogger` filters below `warning` in release and
`ErrorReporter.use(...)` is not wired in `sanad_client`, so today diagnostics are
effectively debug-only.

---

## 12. Failure behaviour

An invalid or hostile payload degrades the **bubble**, never the chat.

| Situation | Result |
|---|---|
| Unknown node with `fallbackText` | renders as plain text |
| Unknown node without it | dropped (release) / labelled marker (dev) |
| Unhandled action on a button | whole button dropped — a dead control is worse than a missing one |
| Unhandled action on a chip | chip stays, tap removed |
| Remote image URL | rejected at validation; no request is issued |
| Limits exceeded | truncate or reject per the protocol |
| A renderer throws | that subtree renders nothing; `renderer_failure` reported |

The `try`/`catch` in `AiUiRenderScope.renderChild` catches throws during **widget
construction**, not during layout or paint. An app wanting to survive those too
should scope an `ErrorWidget.builder` around its chat page.

---

## 13. Prototype boundaries

Deliberately absent, and not stubbed:

- real WebSocket / backend integration
- conversation persistence
- analytics wiring
- production authentication
- production route exposure — `AiChatModule` registers `/dev/ai-chat` only when
  `!kReleaseMode`, so the path does not exist in a release build
