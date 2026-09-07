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
| **Dictation** | mic → native recogniser → text | editable composer text | the microphone, trailing edge |
| **Voice note** | mic → AAC file → attachment **+ on-device transcript** | a message attachment carrying its own words | inside the `+` attach sheet |
| **Live voice** | continuous mic → session → assistant audio | a conversation turn | the waveform button, beside `+` |

`AiComposerBloc` owns the first two and refuses to run either while the other
holds the microphone; live voice is its own bloc on its own route, reached by
`push` so the conversation stays alive underneath.

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
| `ai_chat_config.dart` | URL policy, the eight supported actions, published asset ids, validator factory |
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
| `presentation/bloc/audio_playback_controller.dart` | Playback position, off bloc state; one player for the screen |
| `data/sse_frame_parser.dart` | `text/event-stream` framing — incremental, total, never throws |
| `data/websocket_ai_chat_event_source.dart` | Reference transport (`?transport=ws`): `wss`, `Sanad-Access-Token`, reconnect |
| `data/mock_ai_chat_event_source.dart` | Scripted replay with realistic pacing |
| `data/mock_scenarios.dart` | The twelve scenarios |
| `presentation/bloc/ai_chat_bloc.dart` | Conversation state; parses `ui` once at ingestion |
| `presentation/bloc/active_stream_controller.dart` | Streaming text, bypassing bloc state |
| `presentation/actions/ai_chat_action_handlers.dart` | The eight handlers, the capability seam, registry builder |
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

- `request_location_share` reaches a stub capability: the app acknowledges the
  request but has no location flow yet. (`request_image_upload` now has a real
  upload behind it.)
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
- No conversation persistence — state is lost on navigation.
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
