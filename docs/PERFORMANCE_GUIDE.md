# Performance Guide

## Responsive Layout

- Design size: **360×800** via `ScreenUtilInit` at app root
- Use `AppSpacing.*` and `AppDimension.*` — never `.w` / `.h` on primitives
- No `MediaQuery.of(context)` in build methods

## Const Widgets

Mark every widget `const` when it accepts no dynamic data:

```dart
const AppButton(label: 'Submit', onPressed: _onSubmit)  // if onPressed is const-compatible
const SizedBox(height: AppSpacing.md)  // use token, not literal
```

Token/color classes use `const` constructors.

## List Performance

- `ListView.builder` / `GridView.builder` for lists with > 3 items
- `const` item widgets where possible
- Stable `Key` on list items
- `SliverList` + `SliverToBoxAdapter` for mixed scroll content

## BLoC Optimization

- `BlocSelector` when only a subset of state is needed
- `BlocBuilder`'s `buildWhen` to limit rebuilds
- Debounce events for search/scroll interactions

## Image Optimization

- `CachedNetworkImage` for remote images
- Explicit `width`/`height` to prevent layout shift
- `memCacheWidth` for large images
- Local PNG assets ≤ 200 KB

## Memory Management

Always in `dispose()`:
- `TextEditingController.dispose()`
- `FocusNode.dispose()`
- `ScrollController.dispose()`
- `AnimationController.dispose()`
- Cancel stream subscriptions

## Rendering

- Avoid `Opacity` widget — use `Color.withOpacity` on specific elements
- `addPostFrameCallback` only when absolutely necessary
- No `setState` for global/network state — use BLoC

## Avoid

| Anti-pattern | Alternative |
|-------------|-------------|
| `setState` for API data | BLoC |
| `Column` with many `if` | Conditional list or `Visibility` |
| `ListView` with fixed children | `ListView.builder` |
| `MediaQuery.of(context)` in build | `ScreenUtil` globals |
| `Opacity` widget | `Color.withOpacity` |
