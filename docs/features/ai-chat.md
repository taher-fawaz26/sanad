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

The chat accepts **images and documents**, offers **Speech-to-Text** from the
composer microphone, and has a separate **live-voice** surface at
`/dev/ai-chat/voice`. All of it is real on the device — real camera, real file
picker, real speech recognition, real permissions. Attachments reach the backend
for real: they are uploaded through `packages/media_upload` and sent on the turn
as `{id, url}` pairs. Live voice is still the exception — it has no realtime
protocol and echoes its own capture.

**AI Chat does not send recorded audio.** Speech is converted to text on the
client and submitted as a normal text message; there is no voice-note
attachment, no audio upload and no audio field on the wire. A recorded-audio
capability existed here once — a held microphone producing an AAC file, a
waveform, a preview player and an `AiAudioAttachment` carrying its own
transcript — and it was **retired as a product decision**, removed rather than
disabled. See [§Retired: recorded audio](#retired-recorded-audio).

### Two microphone capabilities, kept distinct

They share a device but nothing else: different outputs, different lifecycles,
different backend contracts. The composer gives each its own affordance rather
than one overloaded button.

| Capability | Path | Produces | Affordance |
|---|---|---|---|
| **Speech-to-Text** | mic → native recogniser → text | editable composer text, sent as an ordinary text turn | the microphone, trailing edge — **tap** it |
| **Live voice** | continuous mic → session → assistant audio | a conversation turn, no attachment | the waveform button, beside the microphone |

`AiComposerBloc` owns the first; live voice is its own bloc on its own route,
reached by `push` so the conversation stays alive underneath. Neither can hold
the microphone while the other does — the dictation bar replaces the composer's
input row, so the live-voice control is not on screen while recognition runs.

### Speech-to-Text

Tapped, not held. There is no take to protect against a mis-tap and no coaching
hint, because nothing is recorded:

```text
tap mic     → requestingPermission → starting → listening
speaking    → partial results stream into the text field, live
stop        → finalizing → completed; the words are ordinary editable text
cancel      → idle, and the words are discarded
send        → an ordinary text turn: { conversation_id, message }
```

The user can edit the transcript before sending, and the request the agent
receives is byte-identical to one the user typed.

- **Real device recognition** (`speech_to_text`), not a mock. The recognition
  locale is chosen by `SpeechLocaleResolver` from what the device actually
  offers; a language with no recogniser installed falls back to the device
  default rather than failing.
- **Partial transcripts travel on `SpeechTranscriptController`**, never through
  bloc state, so the conversation does not rebuild on every recognised word.
  `AiSpeechStatus` — the lifecycle the user can see — is the only part that is
  state.
- The recogniser can end a phrase itself after its own pause; the bloc follows
  with `AiComposerSpeechEnded` rather than going on claiming to listen.
- Two grants are requested, in order: the microphone (Android's `RECORD_AUDIO`,
  which the system recogniser needs) and then iOS's separate speech-recognition
  grant. `SpeechToTextRecognizer` deliberately does **not** touch
  `AudioSessionManager` — the platform recogniser owns its own capture, and
  taking focus here would only give us a grant to fight it with.
- The microphone gives way to the send pill as soon as there is anything to
  send, which is why dictation always begins from an empty composer and
  replaces rather than appends.

### Attachments

- All three sources implement `AiMultimodalEventSource`. A turn's attachments
  are uploaded at send time and travel as exactly `{id, url}` — no
  discriminator, no per-type extras. See
  [`../ai-chat/PROTOCOL_V1.md`](../ai-chat/PROTOCOL_V1.md) §12 for the
  normative shape.
- An upload failure sends nothing and raises one error bubble; the user's text
  stays in their own bubble.
- Live voice captures genuine PCM and plays it back as the "assistant" reply.
  Echoing the capture is the point: a canned clip would leave capture and
  playback unconnected, so a broken microphone would still demo convincingly.
- One conversation holds text, image and document turns interleaved in the same
  list.
- Attachments are bounded by `FileSizePolicy` (5 MiB, repo-wide, not loosened).

### Retired: recorded audio

The composer used to record voice notes. That capability is gone, and the code
went with it — model, serialization, recorder, playback, waveform, gesture,
preview UI, state machine, localization and tests. It is **not** dormant behind
a flag, and it must not be reintroduced through the wire contract: an AI Chat
turn has no `type: "audio"` attachment and no `transcript` field, and
`ai_chat_turn_payload_test.dart` asserts that no audio vocabulary can be
serialized at all.

What remains, and why it is legitimate:

| Kept | Why |
|---|---|
| `record` (package), `RecordVoiceCapture` | live-voice PCM capture |
| `just_audio`, `AiAudioPlayer`, `JustAudioPlayer` | live voice plays the assistant's reply |
| `audio_session`, `AudioSessionManager` | live voice is the app's one audio-focus client |
| `AudioLevelScale`, `LevelHistory`, `WavHeader` | live-voice level metering and PCM framing |
| `RECORD_AUDIO`, `NSMicrophoneUsageDescription`, `PermissionType.microphone` | required by the system speech recogniser *and* by live voice |

### Two lifecycle signals, deliberately not merged

An **audio-session interruption** (a call, another app taking the audio path)
arrives on `AudioSessionManager.events` and belongs to live voice. An
**app-lifecycle transition** (the OS putting us behind something else) arrives
on an `AppLifecycleListener` owned by each screen and becomes
`AiComposerBackgrounded` / `AiVoiceSessionBackgrounded`.

They are separate because they mean different things and nothing reports the
second: Android stops delivering microphone data to a backgrounded app without
a foreground service, so a capture that survives it is already dead. On
background the composer cancels dictation and discards the partial transcript;
the voice route ends its session.

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

## The hero

Figma `Frame 427319459` (`7118:29598`) — the green bloom with Sanad's sparkle
riding on it, shown only while the screen is in its landing composition and
**removed from the tree** once a conversation starts. `AiHeroVisual`
(`presentation/widgets/home/ai_hero_visual.dart`).

The **bloom is Figma's own `bg` node** (`8245:35005`), shipped as
`AppImages.aiChatHeroBloom`. A PNG rather than an SVG on purpose: the design is
two gradient shapes under an `feGaussianBlur`, and `flutter_svg` does not
implement SVG filters, so a vector export of that node renders as two
hard-edged blobs. The export is 267 square for a 200dp node — the extra 33.5
per side is the blur's bleed — and is drawn at 267dp inside the 280dp box the
composition has always occupied, so nothing around it moves.

The **motion is `AppBreathe`**: a four-second loop, scale 1 → 1.02 → 1 and
opacity 85% → 100% → 85%, eased `cubic-bezier(0.42, 0, 0.58, 1)` between each
keyframe — which is CSS `ease-in-out`, and therefore `AppMotionCurve.standard`
with no translation needed. It replaces the self-animating Lottie that used to
sit here (a rotating aura ring looping every 5s): a still image under one
animated widget reproduces the specified keyframes exactly, where a
self-animating composition could only have had them layered on top of a second
rhythm. `AppLottie` and its assets are untouched and still serve the loaders
they were built for.

The breathe is applied to the bloom and **not** to the mark. The specification's
subject is the background; fading the logo to 85% would be a change to the logo.
`AppSvgs.aiChatHeroMark` keeps the node's exact asset, size, offset and 179.66°
rotation.

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

### Swipe actions

Figma `actions` (`8487:31503`). A swipe on a row reveals Delete then Rename as
**one contiguous strip**: 64dp cells with no gap and no inset, full row height,
clipped once to the card's own 20dp corner on the outer edge and a tighter 12
where the card slides away from it. That composition is the design system's
`AppSwipeActionsStyle.grouped`, added beside the `separated` pills the provider
app's list rows already ship — the two are whole visual specs (cell width,
corner treatment, neutral colours, glyph size), not one knob, and the provider
screens are deliberately untouched.

`ConversationHistorySwipeRow` names *which* actions a conversation has and
nothing else. Delete leads, because the destructive action belongs nearest the
swiping thumb, and it uses the design system's `destructive` variant — the
error token, not Figma's raw `#EB4D3D`, so the affordance and its confirmation
cannot disagree about how serious this is.

Motion comes from `AppSwipeActionMotion` in `app_animations`; this feature
declares no duration of its own, and a test enforces that. The reveal is driven
by the pane's own `0 → 1` opening value rather than a ticker, so the contents
track the finger in both directions and nothing is left to cancel when a row
scrolls away.

### Delete and Rename dialogs

Figma `8516:32425` and `8516:32435`. Both go through `showAppDialog` — the
app's single dialog entry point, so both get one surface, one barrier and one
enter/exit animation, and cannot drift apart. Delete confirms with the
destructive CTA; Rename pre-fills `AppPopoverActions.textInput`'s field with the
current title and treats cancel, a blank name and an unchanged name identically.

Two defaulted options were added to `AppPopover` for these: `alignment`
(Figma's task modals read as a short form, so their copy sits on the leading
edge rather than centred) and `secondaryOutlined` (Cancel is outlined here,
filled on the alert-style popovers). Every existing caller keeps its current
rendering.

The rename field's `TextEditingController` is owned by `HistoryPage`, not by
the dialog helper: a controller created with the dialog would have to be
disposed when the future completes, which is the moment the exit transition
*starts* — leaving the still-mounted field reading a disposed controller for
the length of the animation.

Delete and rename are applied to the in-memory list rather than pushed back
through `ConversationHistorySource`. That seam is a *read*; giving it write
methods would mean designing the mutation contract — optimistic or not, what a
failure looks like, what a conflict looks like — for an endpoint that does not
exist.

---

## Try it

Run `sanad_client` in a debug build and navigate to `/dev/ai-chat`. That is the
whole setup: there is no demo route, no query parameter and no picker.

A dev build defaults to `AppConfig.useMockBackend`, so the chat talks to
`MockAiChatEventSource` — a stand-in that walks one deterministic Home Cleaning
journey. Type *"I need a home cleaning tomorrow at 10 AM"* and it runs end to
end: `location_picker` → `permission_request` → `media_request` →
`provider_search` → `provider_card` → `booking_summary` + `confirm_prompt` →
`appointment_card` + `payment_receipt` → `reminder_card` → `service_timeline` →
`verification_code` → `review_request`.

Every one of those is an existing AI UI Protocol node drawn by the existing
renderer. **Only the backend is simulated** — the map, the permission dialog and
the photo picker are the app's own, reached through the same capabilities a live
agent's payload reaches. A restart chip above the composer starts a fresh run.

To talk to the real agent from a dev build instead:

```sh
fvm flutter run --dart-define=MOCK_BACKEND=false
```

Requests renders the shipped screen against deterministic fixtures in the same
mock build, at the ordinary `/dev/ai-chat/requests` — see
[client-requests.md](client-requests.md).

Conversation History is at `/dev/ai-chat/history`; append `?state=empty` for the
empty state. Both states are reachable in a debug build without a rebuild and
without any mock behaviour that could survive into release — the route itself
does not exist there.

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
| `domain/entities/ai_chat_attachment.dart` | Sealed image / document attachment; a path, never bytes, never audio |
| `domain/services/*.dart` | The capability seams: picker, permissions, recogniser, player, voice capture, voice session |
| `domain/usecases/validate_attachment.dart` | Type, size and count rules; delegates the ceiling to `FileSizePolicy` |
| `data/platform/attachments/*.dart` | The only files that name `asset_picker` / `packages/permissions` |
| `data/platform/speech/speech_to_text_recognizer.dart` | The only file that names `speech_to_text`; the whole of the composer mic |
| `data/platform/audio/*.dart` | Live-voice audio focus, playback and PCM framing — the only files that name `just_audio` / `audio_session` |
| `data/platform/voice/record_voice_capture.dart` | The only file that names `record`; live-voice PCM capture |
| `data/platform/voice/mock_ai_voice_session.dart` | Real microphone, mocked assistant (it echoes the capture) |
| `presentation/bloc/ai_composer_bloc.dart` | Staging a turn: attachments, validation, the dictation state machine |
| `presentation/bloc/ai_voice_session_bloc.dart` | The live-voice subsystem's lifecycle |
| `presentation/bloc/speech_transcript_controller.dart` | The live partial transcript, off bloc state |
| `presentation/widgets/composer/ai_speech_bar.dart` | What the composer card wears while the recogniser is listening |
| `src/ui/glass/` | `ClientGlassSurface` / `ClientGlassTokens` — the client's translucent chrome |
| `data/sse_frame_parser.dart` | `text/event-stream` framing — incremental, total, never throws |
| `data/websocket_ai_chat_event_source.dart` | Reference transport: `wss`, `Sanad-Access-Token`, reconnect |
| `data/mock_ai_chat_event_source.dart` | The local stand-in: wire envelopes, pacing, the contextual channel |
| `data/journey/ai_journey_engine.dart` | The stand-in's memory — pure, synchronous, reads only structured answers |
| `data/journey/ai_journey_blocks.dart` | Its payloads, in wire shape, held to the live validator's policy |
| `data/journey/ai_journey_fixtures.dart` | The one data set every card in the journey is built from |
| `domain/ai_contextual_event_source.dart` | Opt-in marker: a transport that also publishes contextual content |
| `presentation/bloc/ai_chat_bloc.dart` | Conversation state; parses `ui` once at ingestion |
| `presentation/bloc/active_stream_controller.dart` | Streaming text, bypassing bloc state |
| `presentation/actions/ai_chat_action_handlers.dart` | The eleven handlers, the capability seam, registry builder |
| `presentation/pages/ai_chat_screen.dart` | Owns the source for one visit |
| `presentation/pages/ai_chat_page.dart` | Conversation, contextual layer and composer |
| `presentation/widgets/context/ai_chat_layout.dart` | The three-slot z-order: conversation, context layer, composer on top |
| `presentation/widgets/context/ai_chat_context_layer.dart` | Chat-owned sliding surface — glass at rest, opaque when open |
| `presentation/widgets/context/ai_chat_context_controller.dart` | Its collapsed/peek/expanded request channel |
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
3. If the mock journey should show it, add a builder to
   `data/journey/ai_journey_blocks.dart`. `ai_journey_blocks_test` then holds it
   to the live validator's policy and asserts it names a catalog type with a
   renderer — the same bar a backend payload clears.
4. Check it on a device through `/dev/ai-chat`, in both directions and at 2×
   text scale. Tests do not tell you whether it matches the design.
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
- `ai_chat` — tests across transports, the two blocs, the composer widgets and
  the module's route tree, plus `test/features/ai_chat/journey/`, which holds
  the mock journey to the live contract: `ai_journey_engine_test` walks the
  state machine, `ai_journey_blocks_test` proves every payload names a catalog
  node with a renderer and survives the release validator, and
  `ai_journey_render_test` draws each stage through the real registry. The ones
  most worth knowing about:
  `ai_composer_bloc_test.dart` (the dictation state machine, plus *speech is
  text, and only text* — the group that pins the product decision that a
  dictated turn stages no attachment), `ai_chat_turn_payload_test.dart`
  (*no audio attachment can be serialized*, which is the wire half of the same
  invariant), and `ai_composer_widget_test.dart` (which surface renders for
  which state, and that the mic dictates on a plain tap).
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
  does, an image- or document-only turn reaches the agent as an empty
  `message`, which the live agent answers with `200` and zero frames. A
  dictated turn is unaffected: its words are ordinary `message` text.
- A failed turn has no retry affordance: `AiChatMessage.user` is always
  `complete`, so a bubble cannot render as failed.
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
- The page chrome (composer, empty state) has no widget test —
  it needs a localization-aware pump helper that `packages/testing` does not yet
  provide. Bubble, renderer and bloc are all covered.
- No golden tests; the repo has no golden infrastructure yet.
- Dictation always begins from an **empty** composer and replaces rather than
  appends: the microphone gives way to send as soon as there is text, so there
  is no affordance for dictating onto a half-typed message.
- Arabic recognition depends on the device having Arabic speech data installed.
  Where it is absent the resolver falls back to the device default — verified on
  an emulator that reported ten locales and no Arabic at all.
