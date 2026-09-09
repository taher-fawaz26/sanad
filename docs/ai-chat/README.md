# AI Chat documentation

The SANAD AI assistant renders native UI inside chat bubbles from a validated
JSON payload. The chat talks to the **live agent over a WebSocket**; the
scripted mock is still there behind `/dev/ai-chat?mock=1` for the failure
scenarios. The route exists only in non-release builds.

| Doc | Read when you need… |
|---|---|
| [`AI_CONTRACT.md`](AI_CONTRACT.md) | **To build the agent.** The complete agent-facing rules: envelope, all 32 components (15 primitives + 17 semantic), the eleven actions, limits, valid and invalid examples. No Flutter knowledge required. |
| [`PROTOCOL_V1.md`](PROTOCOL_V1.md) | The normative client-side reference — every field, default, limit and failure behaviour the validator enforces. |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | How the packages, transport seam, renderer registry and action registry fit together, and why. |
| [`BACKEND_TICKET.md`](BACKEND_TICKET.md) | The implementation-ready ticket for the AI/backend team, with acceptance criteria. |
| [`../features/ai-chat.md`](../features/ai-chat.md) | Running the prototype, key files, how to add a component or an action. |
| [`../adr/0009-ai-chat-ui-protocol.md`](../adr/0009-ai-chat-ui-protocol.md) | Why a bespoke semantic protocol rather than `rfw`, `stac`, `genui`, or a chat package. |

## The short version

- The agent describes **intent** (`service_card`), never Flutter layout
  (`Container`). Widgets, colours, pixels and fonts are not representable.
- The agent **requests** actions from a fixed catalog; the app decides what they
  do and whether they are allowed.
- Payloads are untrusted and validated before rendering. Anything invalid
  degrades one bubble — the chat never breaks.
- `schemaVersion` is the integer `1`. Images are `assetId`-only. Six actions are
  implemented. Every semantic node needs a `fallbackText`.
- Going the other way, a turn carries `attachments` as `{id, url}` pairs,
  uploaded before the request — so the agent resolves no storage. A voice note
  adds `type: "audio"` and the transcript its own device produced, so nothing
  transcribes it twice. One message, audio and words together.

## Source of truth

`packages/ai_ui_protocol` is the authority. These documents describe the
implementation as frozen; where they disagree with the code, the code is right
and the document is a bug.
