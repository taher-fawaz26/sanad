---
name: performance_review
description: Review Flutter performance — rebuilds, const, memory, images, lists, BLoC
---

# Performance Review Skill

Review code for Flutter performance issues.

## Widget Rebuild Analysis

- [ ] `BlocBuilder` uses `buildWhen` to limit rebuilds
- [ ] `BlocSelector` used when only subset of state needed
- [ ] No `setState` causing full subtree rebuilds
- [ ] `const` constructors on stateless widgets

## Const Audit

```bash
rg "Widget\(" --glob "*.dart" | head -50  # spot-check for missing const
```

- [ ] Static widgets marked `const`
- [ ] Token/color classes use `const` constructors

## Memory Management

- [ ] `TextEditingController` closed in `dispose()`
- [ ] `FocusNode` disposed in `dispose()`
- [ ] `ScrollController` disposed in `dispose()`
- [ ] Stream subscriptions cancelled in `dispose()`
- [ ] `AnimationController` disposed in `dispose()`

## Image Optimization

- [ ] `CachedNetworkImage` for remote images
- [ ] Explicit `width`/`height` to prevent layout shift
- [ ] `memCacheWidth` set for large images
- [ ] Local assets optimized (PNG ≤ 200 KB)

## List Optimization

- [ ] `ListView.builder` / `GridView.builder` for lists > 3 items
- [ ] `const` item widgets where possible
- [ ] Stable `Key` on list items
- [ ] No rebuilding list items on unrelated state changes

## BLoC Optimization

- [ ] `BlocSelector` instead of `BlocBuilder` when possible
- [ ] Events debounced where appropriate (search, scroll)
- [ ] No unnecessary state emissions

## Rendering

- [ ] Avoid `Opacity` widget — use `Color.withOpacity` on specific elements
- [ ] `SliverList` + `SliverToBoxAdapter` for mixed scroll content
- [ ] No `addPostFrameCallback` unless necessary

## Output

Report findings with estimated impact (High/Medium/Low) and fix recommendation.
