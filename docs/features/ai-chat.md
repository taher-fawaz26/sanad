# AI Chat (prototype)

An in-app assistant whose replies can contain native SANAD UI — cards, buttons,
lists and business-domain components — rendered from a validated JSON payload.

**Status: prototype, live transport.** The chat talks to the real agent over an
authenticated **streamed `POST`** (SSE) — `POST /user-agent/chat/stream`. This
is a temporary transport choice while the agent team finalises the WebSocket
contract; the socket source is retained and reachable with
`/dev/ai-chat?transport=ws`. There is still no persistence, no analytics and no
production route — the route exists only in non-release builds, and
`/dev/ai-chat?mock=1` replays the scripted scenarios (including the
deliberately-broken payloads) with no network.

## Multimodal

The chat accepts **images, documents and voice notes**, offers **dictation**
(speech-to-text), and has a separate **live-voice** surface at
`/dev/ai-chat/voice`. All of it is real on the device — real camera, real file
picker, real microphone, real speech recognition, real playback, real
permissions. Attachments now reach the backend for real: they are uploaded
through `packages/media_upload` and sent on the turn as `{id, url}` pairs. Live
voice is still the exception — it has no realtime protocol and echoes its own
capture.

### Three microphone capabilities, kept distinct

They share a device but nothing else: different outputs, different lifecycles,
different future backend contracts. The composer gives each its own affordance
rather than one overloaded button.

| Capability | Path | Produces | Affordance |
|---|---|---|---|
| **Voice note** | mic → AAC file → attachment **+ on-device transcript** | a message attachment carrying its own words | the microphone, trailing edge — **hold** it |
| **Dictation** | mic → native recogniser → text | editable composer text | inside the `+` attach sheet |
| **Live voice** | continuous mic → session → assistant audio | a conversation turn | the waveform button, beside the microphone |

`AiComposerBloc` owns the first two and refuses to run either while the other
holds the microphone; live voice is its own bloc on its own route, reached by
`push` so the conversation stays alive underneath.

The first two swapped places. The prominent microphone used to mean dictation
while recording hid inside the attach sheet, which put the capability that
produces a *message* two taps behind the one that produces *text*, and left two
microphone meanings competing on one row. The microphone is now the voice-note
path and nothing else; dictation moved into the sheet with the other things you
reach for occasionally.

### The record gesture

Held, not tapped — `AiHoldToRecordButton` over a `LongPressGestureRecognizer`
whose deadline, lock distance and cancel distance are constants in
`ai_recording_gesture.dart`.

```text
tap            → a hint, never a take
hold           → recording, and it ends when you let go
hold + swipe ↑ → lockedRecording: hands-free, ends at an explicit Stop
hold + swipe ⇤ → discarded, file deleted        (mirrored under RTL)
release        → encoding → preview → send
```

`lockedRecording` is one extra value on `AiRecordingStatus`, not a second
recording path: nothing is asked of the recorder when a take locks, because the
microphone is already open. It joins `isCapturing`, which is what carries it
into the duration cap, backgrounding cleanup and the mutual-exclusion check
without a new call site.

A take shorter than `AiAttachmentRules.minRecordingDuration` is discarded rather
than attached — a fumbled release is a mis-tap, not a message.

**`sequential()` orders events only within one event type.** `Bloc.on<E>`
filters the event stream by `E` before applying the transformer, so a stop runs
*concurrently* with a start rather than queueing behind it. A release that beats
the take it belongs to — the shape of the first-ever permission dialog, which
steals the pointer while the handler is parked on `ensureMicrophone()` — is
therefore latched by `_startInFlight` / `_pendingRelease` and replayed once the
take exists. Without that the take starts with nobody holding it and runs to the
five-minute cap. `_releaseInFlight` is the same idea for the other pair: at most
one terminal transition per take, so a cancel-drag that also ends in a release
cannot call `stop()` on a recorder the cancel already tore down.

Screen-reader users get a plain tap that starts an *already locked* take, so
Stop and Delete are the whole interaction and no gesture is required to reach
any function. The drag path stays available to everyone else.

A voice note also gets a transcript, and that does **not** make it a fourth
capability. `speech_to_text` can only transcribe the live microphone — there is
no file API — so the recogniser runs alongside the recorder for the duration of
the take, writing to an accumulator instead of the composer's text field. It
never enters `state.speech`, which is what keeps the mutual-exclusion rule,
`canSend` and the composer's bar-swapping exactly as they were. Capture is
best-effort: an unavailable recogniser, a microphone it cannot share, or silence
all yield an empty transcript, no banner, and a voice note that still sends.

- All three sources now implement `AiMultimodalEventSource`. A turn's
  attachments are uploaded at send time and travel as `{id, url}` — plus
  `type: "audio"` and `transcript` for a voice note — so the agent never
  resolves a storage location itself and never re-transcribes. See
  [`../ai-chat/PROTOCOL_V1.md`](../ai-chat/PROTOCOL_V1.md) §12 for the
  normative shape.
- An upload failure sends nothing and raises one error bubble; the user's text
  and their audio stay in their own bubble, and the audio stays playable.
- Live voice captures genuine PCM and plays it back as the "assistant" reply.
  Echoing the capture is the point: a canned clip would leave capture and
  playback unconnected, so a broken microphone would still demo convincingly.
- One conversation holds every modality — image, audio, document and text turns
  interleave in the same list.
- Attachments are bounded by `FileSizePolicy` (5 MiB, repo-wide, not loosened);
  recordings are capped at five minutes, which keeps a take well inside it.
- Dictation is **real** device recognition (`speech_to_text`), not a mock. The
  recognition locale is chosen by `SpeechLocaleResolver` from what the device
  actually offers; a language with no recogniser installed falls back to the
  device default rather than failing.
- Partial transcripts travel on `SpeechTranscriptController`, never through
  bloc state — the same hot-path rule as the recording meter and the playback
  position, so the conversation does not rebuild on every recognised word.

### Two lifecycle signals, deliberately not merged

An **audio-session interruption** (a call, another app taking the audio path)
arrives on `AudioSessionManager.events` and is classified by
`RecordAudioRecorder.abortFor`. An **app-lifecycle transition** (the OS putting
us behind something else) arrives on an `AppLifecycleListener` owned by each
screen and becomes `AiComposerBackgrounded` / `AiVoiceSessionBackgrounded`.

They are separate because they mean different things and nothing reports the
second: Android stops delivering microphone data to a backgrounded app without
a foreground service, so a capture that survives it is already dead. On
background the composer cancels dictation, aborts a recording *and deletes its
partial file*, and stops playback; the voice route ends its session.

> **Backend gap:** the streaming endpoint emits **no `ui` event** — replies are
> prose only, in Markdown. The whole structured-UI pipeline (codec, validator,
> renderer, action registry) is unchanged and still wired, so it lights up the
> day the agent starts sending one. See [the backend
> ticket](../ai-chat/BACKEND_TICKET.md#10-gaps-observed-on-user-agentchatstream).

| | |
|---|---|
| Feature | `apps/sanad_client/lib/src/features/ai_chat/` |
| Packages | [`packages/ai_ui_protocol`](../../packages/ai_ui_protocol) (tier 0), [`packages/ai_ui_renderer`](../../packages/ai_ui_renderer) (tier 3) |
| Route | `AiChatRoutes.chat` = `/dev/ai-chat` — registered only when `!kReleaseMode` |
| Module | `AiChatModule`, registered in `apps/sanad_client/lib/src/di/app_di.dart` |
| L10n | `ai_chat.*`, `permissions.speech_*` in `en-US.json` / `ar-AR.json` |
| Docs | [protocol](../ai-chat/PROTOCOL_V1.md) · [agent contract](../ai-chat/AI_CONTRACT.md) · [architecture](../ai-chat/ARCHITECTURE.md) · [backend ticket](../ai-chat/BACKEND_TICKET.md) · [ADR-0009](../adr/0009-ai-chat-ui-protocol.md) |

---

## Glass surfaces

The client's chrome is translucent over the AI background rather than painted
on top of it — `ClientGlassSurface` in `apps/sanad_client/lib/src/ui/glass/`,
applied to the Home header's nav pill and History button and to the composer
card. Three levels (`nav`, `surface`, `floating`) fix the blur, tint, border and
shadow so two surfaces at the same depth match; a caller says what the surface
*is*, never how blurred it should be.

A `BackdropFilter` is the most expensive widget in this app's vocabulary, so
the component makes the two invisible mistakes impossible instead of documenting
them. Every instance publishes a scope and asserts no glass ancestor, so nesting
fails loudly in debug rather than silently costing two full passes; the filter
lives inside the `ClipRRect`, so it samples only the surface's own bounds and
there is no full-screen blur layer anywhere in the client; and a
`RepaintBoundary` outside the clip stops blurred chrome repainting with the
conversation scrolling behind it.

It sits **on top of** the existing backgrounds and replaces none of them.
`AiChatBackground`'s wash, the landing state's `AppAmbientGradient` and the
live-voice backdrop are untouched — showing them through the chrome is the
entire point. The nav pill's *selected* segment stays opaque, because its label
is the one piece of text on that control.

## Conversation History

Figma `8120:2918` (with conversations) and `8124:3867` (without). Reached by
push from the Home header's History button, on top of `AiHomeShell` rather than
inside one of its branches, so it covers the whole shell — including the
persistent header, which is why the page draws navigation of its own and
repaints `AiChatBackground` the way `AiChatPage` does.

**One screen, two renderings.** Which appears is decided by the data and
nothing else — an empty collection *is* the empty state. There is no second
route and no flag on the widget, which is what makes the real repository a
drop-in later: "the user has no history" is simply what it will return.

**No bloc, on purpose.** The screen loads a list once and filters it in memory:
no async lifecycle to model, no mutation to guard, no failure to surface. The
seam is a one-method `ConversationHistorySource`; `MockConversationHistorySource`
implements it with local fixtures, and search is the pure
`filterConversationHistory(entries, query)`. Swapping in a repository backed by
the history endpoint touches neither.

**Search** is the shared `AppSearchField` carrying Figma's own spec (52dp on a
16dp radius, 20dp glyph, 14dp type) through a scoped `Theme` that overrides the
`AppSearchBarTheme` extension for that subtree — the same mechanism the
component already reads its spec from, so nothing changes for the screens using
the shared 40/8 bar. The one property the extension cannot reach is the bordered
variant's glyph size, which is why `AppSearchField.iconSize` exists.

The query lives in a `ValueNotifier`, not in `State`: a keystroke has to rebuild
the results and nothing else. Cards are `ListView.separated` rows keyed by
conversation id, so filtering re-parents the survivors rather than rebuilding
every row into a different entry's slot.

**Not glass.** Figma draws opaque white cards on a hairline border here, and a
list of glass rows would mean one `BackdropFilter` per visible card. The
`ClientGlassSurface` treatment stays on the chrome it was built for.

The CTA is a client-local button rather than `AppButton`: geometry, typography
and label colour are identical, but Figma specifies `main/700` (`#1A7E6B`),
where the primary variant resolves `main/600`. That is the AI surface's own
green — the one `AiComposerTokens.accent` already documents — so the screen
follows the surface it belongs to instead of repointing a shared token.

---

## Try it

Run `sanad_client` in a debug build and navigate to `/dev/ai-chat`.

Conversation History is at `/dev/ai-chat/history`; append `?state=empty` for the
empty state, following the `?mock=` / `?transport=` affordances on the chat
route. Both states are reachable in a debug build without a rebuild and without
any mock behaviour that could survive into release — the route itself does not
exist there.

The composer accepts free text; a scenario is picked by keyword (`services`,
`appointment`, `branches`, `book`, `unsupported`, `malformed`, `oversized`, …).
A chip row above the composer forces a specific scenario, including the
deliberately broken ones and a chip that opens the component showcase.
Twenty-six scenarios ship (twelve named here, fourteen from the component set) — `src/data/mock_scenarios.dart` assembles them and
`src/data/scenarios/component_scenarios.dart` holds one per semantic
component, with the state variants the design defines (an order delivered and
active, a branch open and closed, a receipt paid and declined, a slot grid with
one slot taken). Five are failure cases.

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
                                      │
                                      └─► AiUiInteractionSink ─► the loop below
```

### Answering a card — the return leg

```text
user taps Confirm
        │
        ▼
AiUiRenderScope.submitInteraction
        ├─ ledger.beginSubmission(nodeId)   ← refuses a second tap, here only
        └─ builds AiUiInteraction { nodeId, kind, value, text, messageId }
                        │
                        ▼
        AiChatBlocInteractionSink ─► AiChatInteractionSubmitted
                        │
   AiChatBloc ├─ appends AiChatMessage.user(text, interaction)
              └─ source.sendInteraction(interaction, text:)
                        │
                        ▼
        AiChatTurnPayload.encode  → { conversation_id, message, interaction }
                        │
                        ▼
                agent continues ─► message_start → … → ui → message_end
```

Two halves travel: the **sentence** the agent's template produced (in
`message`, unchanged, so a backend that ignores results still works) and the
**structured result** naming the node, the choice and the message that asked.
See [`../ai-chat/PROTOCOL_V1.md`](../ai-chat/PROTOCOL_V1.md) §13.

Live voice runs the identical path with two substitutions: the sink is
`AiVoiceInteractionSink`, and the transport is the session's own channel rather
than a turn body. The nodes, the values, the lifecycle, the validation and the
renderers are one implementation.

---

## Key files

| Path (under `features/ai_chat/src/`) | Role |
|---|---|
| `ai_chat_config.dart` | URL policy, the eleven supported actions, published asset ids, validator factory |
| `domain/ai_chat_message.dart` | One bubble: role, text, validated document, lifecycle |
| `domain/ai_chat_event_source.dart` | The transport seam — three members |
| `data/sse_ai_chat_event_source.dart` | The live transport: streamed `POST`, `Sanad-Access-Token`, one request per turn |
| `domain/entities/ai_chat_attachment.dart` | Sealed image / document / audio attachment; a path, never bytes |
| `domain/services/*.dart` | The capability seams: picker, permissions, recorder, player, voice capture, voice session |
| `domain/usecases/validate_attachment.dart` | Type, size and count rules; delegates the ceiling to `FileSizePolicy` |
| `data/platform/attachments/*.dart` | The only files that name `asset_picker` / `packages/permissions` |
| `data/platform/audio/*.dart` | The only files that name `record`, `just_audio`, `audio_session` |
| `data/platform/voice/mock_ai_voice_session.dart` | Real microphone, mocked assistant (it echoes the capture) |
| `presentation/bloc/ai_composer_bloc.dart` | Staging a turn: attachments, validation, the recording state machine |
| `presentation/bloc/ai_voice_session_bloc.dart` | The live-voice subsystem's lifecycle |
| `presentation/bloc/recording_level_controller.dart` | Live mic level + elapsed, off bloc state |
| `presentation/widgets/composer/ai_hold_to_record_button.dart` | The record gesture: hold, swipe to lock, swipe to discard |
| `presentation/widgets/composer/ai_recording_gesture.dart` | The gesture's thresholds, as constants |
| `src/ui/glass/` | `ClientGlassSurface` / `ClientGlassTokens` — the client's translucent chrome |
| `presentation/bloc/audio_playback_controller.dart` | Playback position, off bloc state; one player for the screen |
| `data/sse_frame_parser.dart` | `text/event-stream` framing — incremental, total, never throws |
| `data/websocket_ai_chat_event_source.dart` | Reference transport (`?transport=ws`): `wss`, `Sanad-Access-Token`, reconnect |
| `data/mock_ai_chat_event_source.dart` | Scripted replay with realistic pacing |
| `data/mock_scenarios.dart` | The scenario list, assembled |
| `data/scenarios/component_scenarios.dart` | One scenario per semantic component, with its state variants |
| `data/scenarios/scenario_support.dart` | The `MockScenario` shape and the event helpers |
| `data/showcase_fixtures.dart` | The same payloads, grouped for the showcase |
| `presentation/pages/ai_ui_showcase_page.dart` | Dev-only catalogue: every semantic type through the real validator and surface |
| `presentation/bloc/ai_chat_bloc.dart` | Conversation state; parses `ui` once at ingestion |
| `presentation/bloc/active_stream_controller.dart` | Streaming text, bypassing bloc state |
| `presentation/actions/ai_chat_action_handlers.dart` | The eleven handlers, the capability seam, registry builder |
| `presentation/pages/ai_chat_screen.dart` | Owns the source for one visit |
| `presentation/pages/ai_chat_page.dart` | Nav bar, message list, scenario picker, composer |
| `presentation/widgets/ai_chat_bubble.dart` | Bubble; hosts `AiUiSurface` for structured UI |
| `module/ai_chat_module.dart` | Dev-gated route contribution, including History's `?state=` fixture switch |

Conversation History lives beside the feature, under
`features/history/` (it is a peer destination, not a chat branch):

| Path (under `features/history/`) | Role |
|---|---|
| `history_page.dart` | The screen; picks its rendering from the loaded list |
| `src/domain/conversation_history_source.dart` | The data seam — one method |
| `src/domain/filter_conversation_history.dart` | Search, as a pure function |
| `src/data/mock_conversation_history_source.dart` | Local fixtures + the `?state=` enum |
| `src/presentation/conversation_history_tokens.dart` | Only the Figma numbers with no design-system token |
| `src/presentation/widgets/conversation_history_search_field.dart` | `AppSearchField` under a scoped spec |
| `src/presentation/widgets/conversation_history_card.dart` | One conversation row |
| `src/presentation/widgets/conversation_history_placeholder.dart` | The illustration + copy, for both empty renderings |

---

## Three things worth knowing before changing this

**Structured UI renders inside the assistant bubble.** `AiUiSurface` sits in the
bubble's column, under the prose — it is part of the reply, not a panel beneath
it.

**A token never rebuilds the conversation.** `text_delta` writes to
`ActiveStreamController` and the bloc emits nothing. Only the streaming bubble,
a `ValueListenableBuilder`, rebuilds. If you add state that changes per token,
you undo this.

**One image contract, one image widget.** Every image-bearing node carries the
same `{url?, assetId?}` object, and `AiUiImageView` is the only place the
`url > assetId > fallback` precedence is implemented. A URL goes through
`AppNetworkImage` — the app's existing cached-network-image widget — so the AI
surface has no image stack of its own. `AiChatConfig.imageUrlPolicy` is where
the accepted origins are decided.

**The validator's allowlists come from the app's registries.**
`AiChatConfig.supportedActions` is the single source of truth: handlers are
registered for exactly that set, and the validator drops anything else *before*
a widget exists. Adding a handler without adding the action type means it can
never fire; a test asserts the two stay in step.

---

## Adding a component

1. Add the node type and its parser to `packages/ai_ui_protocol` — the type to
   `AiUiNodeType` (plus `isSemantic` and, if it takes a card action row,
   `acceptsCardActions`), the node class under `domain/nodes/`, the parser
   under `validation/parsers/`. The validator's dispatch switch is exhaustive,
   so the compiler names what is missing.
2. Write an `AiNodeRenderer` in `packages/ai_ui_renderer` under
   `rendering/renderers/semantic/` and register it in
   `defaultRendererRegistry`. A test fails if you forget.
3. Add a scenario to `data/scenarios/component_scenarios.dart` and a fixture to
   `data/showcase_fixtures.dart` — the showcase test fails until every semantic
   type has one.
4. Check it on a device through `/dev/ai-chat/showcase`, in both directions and
   at 2× text scale. Tests do not tell you whether it matches the design.
5. Document it in [`PROTOCOL_V1.md`](../ai-chat/PROTOCOL_V1.md) and
   [`AI_CONTRACT.md`](../ai-chat/AI_CONTRACT.md), then in the Confluence page
   the AI team builds against.

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
fvm flutter test apps/sanad_client/test/features/ai_chat apps/sanad_client/test/ui
```

- `ai_ui_protocol` — 189 tests: node round-trips through the real validator
  (one per type in the catalog, enforced), the limit matrix, action allowlist,
  URL policy, totality (no input throws).
- `ai_ui_renderer` — 125 tests: one per node type, the interactive cards'
  input and template substitution, degradation, action dispatch, RTL
  mirroring, accessibility.
- `ai_chat` — 667 tests across transports, the two blocs, the composer widgets
  and the module's route tree, plus the showcase net that validates and renders
  every fixture in both directions. The ones most worth knowing about:
  `ai_composer_bloc_test.dart` (the recording state machine, including the
  concurrency latches — every test in *a release that beats the take it belongs
  to* fails without them), `ai_hold_to_record_test.dart` (the gesture, driven
  pointer by pointer in both text directions), and `ai_composer_widget_test.dart`
  (which surface renders for which state).
- `history` — 35 tests over a real router: both Figma states, search
  (matching, non-matching, cleared), scrolling, the preview's two-line cap, the
  interaction boundary, RTL and large text scale, plus the empty state's
  illustration asset asserted **by name** — a substitute icon would still
  satisfy "something renders".
- `test/ui/glass` — 10 tests pinning the cost properties of
  `ClientGlassSurface`: one filter per surface, clipped rather than
  full-screen, nesting trips the assert.

---

## Known limitations

- **The client reads no device position.** `request_location_share` now
  returns a structured `permission_result` with `outcome: "unavailable"`
  instead of ending in a snackbar, so the agent is *told* and can ask the user
  to name the place — but there is still no GPS behind it. `LocationService`
  exists in `packages/maps`, which the client does not depend on; adopting it
  would bring `google_maps_flutter`, a Maps API key and a DI bootstrap for a
  capability the conversation otherwise does not need. A `location_picker`
  answer is fully structured (`id`, `name`, `addressText`, `source`); only
  coordinates are missing.
- **The backend does not read `interaction` yet.** The client sends it on every
  transport. Until the agent parses it, a tapped card behaves exactly as it did
  before — `message` still carries the agent's own sentence. See
  [`../ai-chat/BACKEND_TICKET.md`](../ai-chat/BACKEND_TICKET.md) §12.
- **Live voice has no realtime backend.** A semantic card can arrive
  mid-session, be answered, and let the session resume — but *which* card
  arrives is decided by a local script (`MockVoiceScenarios`), and the
  assistant's audio is still the user's own capture played back. Validation,
  rendering, the ledger, the interaction and the state machine on that path are
  the real ones.
- A `media_request` reports only its **cancellation** as a result. The files
  themselves still arrive as the next turn's `attachments`, uncorrelated with
  the node that asked — the picker returns asynchronously and the user may send
  the photo several turns later, so claiming a count at request time would be a
  fabrication.
- A capability action on a bare `button` produces no result: it carries no
  `nodeId`, so there is no question for the outcome to answer.
- The backend does not read `attachments` yet — see
  [`../ai-chat/BACKEND_TICKET.md`](../ai-chat/BACKEND_TICKET.md) §11. Until it
  does, a voice note is still understood, because its transcript also fills
  `message` when nothing was typed.
- A failed turn has no retry affordance: `AiChatMessage.user` is always
  `complete`, so a bubble cannot render as failed.
- Concurrent recording and speech recognition is **unverified on real
  hardware**. If a platform refuses to share the microphone the transcript is
  simply empty; the wire contract is unaffected either way.
- The transport carries no conversation history — a new visit is a new
  `conversation_id`, so server-side memory starts empty. Within a visit the
  server does remember: turn 2 recalls turn 1 (verified live).
- The agent emits no `ui` events and ignores the access token (it has no
  authenticated tools). Both are backend gaps, not client ones.
- There is no "stop generating" control. Cancelling an in-flight turn is now
  cheap — the transport already does it when a turn is replaced — but exposing
  it would need a fourth member on `AiChatEventSource`.
- No conversation persistence — state is lost on navigation. Conversation
  History is consequently UI-and-fixtures only: there is no history endpoint,
  and nothing in the app can open a *stored* conversation (the transport has no
  conversation id to resume), so a tap on a history card reaches
  `HistoryPage.onConversationSelected` and stops there rather than inventing a
  route.
- `open_url` and `open_route` are unimplemented by design.
- Images are `assetId`-only; there are no remote images in v1.
- Diagnostics reach `appLogger` only, which filters below `warning` in release.
- The page chrome (composer, scenario picker, empty state) has no widget test —
  it needs a localization-aware pump helper that `packages/testing` does not yet
  provide. Bubble, renderer and bloc are all covered.
- No golden tests; the repo has no golden infrastructure yet.
- Dictation always begins from an **empty** composer and replaces rather than
  appends: the microphone gives way to send as soon as there is text, so there
  is no affordance for dictating onto a half-typed message.
- Arabic recognition depends on the device having Arabic speech data installed.
  Where it is absent the resolver falls back to the device default — verified on
  an emulator that reported ten locales and no Arabic at all.
