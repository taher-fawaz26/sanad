# AI Chat (prototype)

An in-app assistant whose replies can contain native SANAD UI — cards, buttons,
lists and business-domain components — rendered from a validated JSON payload.

**Status: prototype.** The transport is a scripted local mock. There is no
backend, no persistence, no analytics and no production route. The route exists
only in non-release builds.

| | |
|---|---|
| Feature | `apps/sanad_client/lib/src/features/ai_chat/` |
| Packages | [`packages/ai_ui_protocol`](../../packages/ai_ui_protocol) (tier 0), [`packages/ai_ui_renderer`](../../packages/ai_ui_renderer) (tier 3) |
| Route | `AiChatRoutes.chat` = `/dev/ai-chat` — registered only when `!kReleaseMode` |
| Module | `AiChatModule`, registered in `apps/sanad_client/lib/src/di/app_di.dart` |
| L10n | `ai_chat.*` in `en-US.json` / `ar-AR.json` |
| Docs | [protocol](../ai-chat/PROTOCOL_V1.md) · [agent contract](../ai-chat/AI_CONTRACT.md) · [architecture](../ai-chat/ARCHITECTURE.md) · [backend ticket](../ai-chat/BACKEND_TICKET.md) · [ADR-0009](../adr/0009-ai-chat-ui-protocol.md) |

---

## Try it

Run `sanad_client` in a debug build and navigate to `/dev/ai-chat`.

The composer accepts free text; a scenario is picked by keyword (`services`,
`appointment`, `branches`, `book`, `unsupported`, `malformed`, `oversized`, …).
A chip row above the composer forces a specific scenario, including the
deliberately broken ones. Twelve scenarios ship in
`src/data/mock_scenarios.dart`; five of them are failure cases.

---

## Flow

```text
user types  ──► AiChatBloc ──► AiChatEventSource.send()
                                      │
                                      ▼
                        MockAiChatEventSource replays
                        message_start → text_delta… → ui → message_end
                                      │
                                      ▼
   AiChatBloc  ├─ text_delta  → ActiveStreamController  (no state emitted)
               ├─ ui          → AiUiValidator.validate  → AiUiDocument
               └─ message_end → authoritative text, message completed
                                      │
                                      ▼
   AiChatBubble ── prose ──► Text
                └─ document ─► AiUiSurface → renderers → App* widgets
                                      │
                                 tap ─► AiActionRegistry ─► app handler
```

---

## Key files

| Path (under `features/ai_chat/src/`) | Role |
|---|---|
| `ai_chat_config.dart` | URL policy, the six supported actions, published asset ids, validator factory |
| `domain/ai_chat_message.dart` | One bubble: role, text, validated document, lifecycle |
| `domain/ai_chat_event_source.dart` | The transport seam — three members |
| `data/mock_ai_chat_event_source.dart` | Scripted replay with realistic pacing |
| `data/mock_scenarios.dart` | The twelve scenarios |
| `presentation/bloc/ai_chat_bloc.dart` | Conversation state; parses `ui` once at ingestion |
| `presentation/bloc/active_stream_controller.dart` | Streaming text, bypassing bloc state |
| `presentation/actions/ai_chat_action_handlers.dart` | The six handlers + registry builder |
| `presentation/pages/ai_chat_screen.dart` | Owns the source for one visit |
| `presentation/pages/ai_chat_page.dart` | Nav bar, message list, scenario picker, composer |
| `presentation/widgets/ai_chat_bubble.dart` | Bubble; hosts `AiUiSurface` for structured UI |
| `module/ai_chat_module.dart` | Dev-gated route contribution |

---

## Three things worth knowing before changing this

**Structured UI renders inside the assistant bubble.** `AiUiSurface` sits in the
bubble's column, under the prose — it is part of the reply, not a panel beneath
it.

**A token never rebuilds the conversation.** `text_delta` writes to
`ActiveStreamController` and the bloc emits nothing. Only the streaming bubble,
a `ValueListenableBuilder`, rebuilds. If you add state that changes per token,
you undo this.

**The validator's allowlists come from the app's registries.**
`AiChatConfig.supportedActions` is the single source of truth: handlers are
registered for exactly that set, and the validator drops anything else *before*
a widget exists. Adding a handler without adding the action type means it can
never fire; a test asserts the two stay in step.

---

## Adding a component

1. Add the node type and its parser to `packages/ai_ui_protocol`.
2. Write an `AiNodeRenderer` in `packages/ai_ui_renderer` and register it in
   `defaultRendererRegistry`. A test fails if you forget.
3. Document it in [`PROTOCOL_V1.md`](../ai-chat/PROTOCOL_V1.md) and
   [`AI_CONTRACT.md`](../ai-chat/AI_CONTRACT.md).
4. Add a scenario to `mock_scenarios.dart`.

Adding a node type is **additive** — it does not bump `schemaVersion`. Older
clients degrade through `fallbackText`.

## Adding an action

1. Add the type to `AiUiActionType` in the protocol.
2. Write an `AiActionHandler`, register it in `buildAiChatActionRegistry`.
3. Add the type to `AiChatConfig.supportedActions` — **both**, or the action is
   either unreachable or renders a dead control.

---

## Tests

```bash
fvm flutter test packages/ai_ui_protocol packages/ai_ui_renderer
fvm flutter test apps/sanad_client/test/features/ai_chat
```

- `ai_ui_protocol` — 118 tests: node round-trips through the real validator,
  the limit matrix, action allowlist, URL policy, totality (no input throws).
- `ai_ui_renderer` — 51 tests: one per node type, degradation, action dispatch,
  RTL mirroring, accessibility.
- `ai_chat` — 34 tests: 16 bloc (event sequencing, streaming, failures) and 18
  widget (mixed content, dispatch, fallback, malformed/oversized payloads).

---

## Known limitations

- The transport is a mock; no WebSocket exists.
- No conversation persistence — state is lost on navigation.
- `open_url` and `open_route` are unimplemented by design.
- Images are `assetId`-only; there are no remote images in v1.
- Diagnostics reach `appLogger` only, which filters below `warning` in release.
- The page chrome (composer, scenario picker, empty state) has no widget test —
  it needs a localization-aware pump helper that `packages/testing` does not yet
  provide. Bubble, renderer and bloc are all covered.
- No golden tests; the repo has no golden infrastructure yet.
