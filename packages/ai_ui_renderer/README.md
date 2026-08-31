# ai_ui_renderer

Draws a validated [`ai_ui_protocol`](../ai_ui_protocol) document as native SANAD
Design System widgets, and dispatches its actions through a compile-time
allowlist.

This is the **only** layer that can act on an AI payload. `ai_ui_protocol` is
inert data by construction (no Flutter dependency at all), so the audit question
*"what can an AI payload actually reach?"* has one small answer, and it lives
here.

Tier **3** in [`dep_rules.yaml`](../../dep_rules.yaml).

## Wiring

```dart
final actions = AiActionRegistry([
  OpenServiceHandler(),
  SendMessageHandler(chatBloc),
]);

final environment = AiUiEnvironment(
  registry: defaultRendererRegistry(showUnsupportedMarker: !kReleaseMode),
  actions: actions,
  assets: const AiAssetResolver.defaults(),
  icons: const AiIconResolver(),
  diagnostics: const LoggingAiUiDiagnosticsSink(),
  strings: AiUiStrings(
    metresSuffix: 'ai_chat.unit_metres'.tr(),
    kilometresSuffix: 'ai_chat.unit_kilometres'.tr(),
    unsupportedContent: 'ai_chat.unsupported_content'.tr(),
  ),
);

// Same allowlists for validation and rendering — see below.
final validator = validatorFor(
  environment,
  urlPolicy: AppConfig.aiUiUrlPolicy,
  keepUnsupportedNodes: !kReleaseMode,
);
```

Then, once per screen:

```dart
AiUiHost(
  environment: environment,
  child: /* ... */ AiUiSurface(document: message.document),
)
```

### Build one validator *from* the environment

`validatorFor` is not sugar. It hands the action registry's real key set and the
asset resolver's real id set to the validator, so:

- an action with **no handler** is dropped before a widget exists — you can
  never render a button that does nothing;
- an `assetId` with **no file** is dropped before an image is built.

Wiring those two independently is the bug this function exists to prevent.

## Where the boundaries are

| Concern | Owner |
|---|---|
| Is this payload well-formed and within limits? | `ai_ui_protocol` |
| Is this URL allowed? | `ai_ui_protocol` (`AiUiUrlPolicy`), at validation time |
| What does `tone: "success"` look like? | `AiUiTokens` |
| How is a price/date/distance formatted? | `AiUiFormatters`, in the device locale |
| What does `open_service` actually do? | the app's `AiActionHandler` |
| Display strings the renderer needs | the host, via `AiUiStrings` |

`ai_ui_renderer` deliberately does **not** depend on `localization`: it is a
presentation library, and pulling easy_localization in would make every consumer
inherit a translation bootstrap. The host injects already-localized strings.

## Adding a node type

1. Add it to the protocol catalog and give it a parser.
2. Write an `AiNodeRenderer<YourNode>`.
3. Register it in `defaultRendererRegistry`.

A test asserts every protocol node type has a renderer, so step 3 cannot be
forgotten silently.

To *specialise* an existing node — say, swapping the composed `service_card` for
a real `AppServiceCard` when one lands — call `registry.register(...)` over it.
No protocol change, no prompt change.

## Failure behaviour

An invalid or hostile payload degrades the **bubble**, never the chat:

| Situation | Result |
|---|---|
| Unknown node type with `fallbackText` | renders as plain text |
| Unknown node type without it | dropped (release) / labelled marker (dev) |
| Unhandled action on a button | whole button dropped — a dead control is worse than a missing one |
| Unhandled action on a chip | chip stays, tap removed — it still reads fine |
| Blocked URL | stripped at validation; never reaches a widget |
| A renderer throws | that subtree renders nothing, `rendererFailure` reported |

The primary defence is *parse, don't validate-at-render*: renderers are total
functions over already-validated data, so there is nothing left to be invalid at
build time. The `try`/`catch` in `AiUiRenderScope.renderChild` is a second line
only, and it catches throws during **widget construction** — not during layout or
paint. An app that wants to survive those too should scope an
`ErrorWidget.builder` around its chat page.

## Tests

```bash
fvm flutter test packages/ai_ui_renderer
```

Every test drives the real validate → render pipeline rather than constructing
documents by hand, so a renderer can never be tested against a node shape the
validator would not actually produce.
