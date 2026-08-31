# ai_ui_protocol

SANAD Chat UI Protocol **v1** — the models, codec, validator and diagnostics for
AI-generated structured UI.

## Why this package is pure Dart

`pubspec.yaml` declares no dependency on Flutter. That is the whole design.

An AI payload parsed here **cannot** reference a `Widget`, a `Color`, an
`IconData`, a route, or the network, because none of those types are reachable
from this package. "AI output is untrusted data, not code" therefore holds
structurally rather than by policy. Rendering and action execution live in
`ai_ui_renderer`, which owns those concerns and is the only place a payload can
actually *do* anything.

It sits at **tier 0** in [`dep_rules.yaml`](../../dep_rules.yaml) because it
depends on nothing.

## Pipeline

```text
raw string
  → AiUiCodec.decode       size guard, JSON decode          — never throws
  → AiUiValidator.validate version, catalog, props, actions, limits
  → AiUiParseResult        AiUiDocument? + List<AiUiDiagnostic>
```

Both stages are **total**: there is no input for which they throw. A malformed
payload degrades the chat bubble, never the chat.

```dart
final validator = AiUiValidator(
  urlPolicy: const AiUiUrlPolicy(allowedHosts: {'cdn.trysanad.us'}),
  supportedActions: actionRegistry.supportedTypes, // the host's real key set
  knownAssetIds: assetResolver.publishedIds,
);

final result = validator.parse(rawPayload);
if (result.hasRenderableUi) {
  // hand result.document to AiUiSurface
} else {
  // fall back to the message's plain text
}
diagnosticsSink.addAll(result.diagnostics);
```

Parse **once**, at event ingestion — never inside `build()`.

## What the protocol deliberately cannot express

- Flutter widgets (`Container`, `Padding`, `Expanded`, `Stack`, …)
- Pixel values, hex colours, font families
- Callbacks, method names, Dart expressions
- Raw route paths or deep links — `open_route` takes a *symbolic key* the app
  resolves through a compile-time map
- Arbitrary URLs — `AiUiUrlPolicy` gates https + a host allowlist during
  validation, so a blocked URL never reaches a widget

Style is expressed as closed semantic enums (`tone`, `emphasis`, `variant`,
`gap`) that the renderer maps onto SANAD design tokens.

## Forward compatibility

`schemaVersion` is an integer, currently `1`. Additive changes — new node types,
new action types, new optional properties — **do not** bump it; older clients
degrade through each node's `fallbackText`. The version moves only when the
meaning of an existing node changes.

Agents must set `fallbackText` on semantic nodes and on anything introduced
after v1.0. That single field replaces capability negotiation.

## Diagnostics and privacy

`AiUiDiagnostic.detail` carries field names, type names, limit numbers and enum
names — **never** user or AI prose. This mirrors the redaction discipline in
`network`'s `logging_interceptor`: the shape of a problem is diagnostic, the
content is not ours to log.

## Tests

```bash
fvm flutter test packages/ai_ui_protocol
```

The suite covers the round-trip of every node type through `toJson` + the real
validator (with a guard that fails when a new node type is added and not
covered), the limit matrix, the action allowlist, the URL policy accept/reject
matrix, and a totality group asserting no adversarial input throws.
