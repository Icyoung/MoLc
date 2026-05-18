# Changelog

## 0.2.1

### Fixes
- Run `refresh(fn)` callbacks before `SelectorMixin` decides whether to notify
  listeners, so callback-style state updates use the same semantics as
  mutating state before calling `refresh()`.
- Reconnect `MoLogic` to the current `modelValue` when `MoLcWidget.value`
  receives a replacement model instance.

### Docs / tooling
- Document that `Mutable` intentionally uses a static build-phase delegate for
  GetX-like automatic dependency tracking on Flutter's synchronous build model.
- Add focused widget tests for `MutableWidget`, provider error paths,
  `top<T>()` pre-mount errors, selector callback refresh, and
  `MoLcWidget.value` model replacement.
- Add package metadata and `.pubignore` entries so local agent files and
  generated artifacts are excluded from the published package.
- Replace the example app's template README with MoLc-specific usage notes.

## 0.2.0

### Breaking changes
- Bumped SDK constraints to Dart `>=3.0.0 <4.0.0` and Flutter `>=3.7.0`.
- Removed the `provider` package dependency. MoLc now uses Flutter's native
  inherited widget mechanism internally.
- `lib/molc.dart` no longer re-exports provider APIs such as
  `ChangeNotifierProvider`, `ReadContext`, `WatchContext`, or `MultiProvider`.
  Use MoLc's native `MoNotifierProvider`, `MoProvider`, `MoMultiProvider`,
  `context.read<T>()`, and `context.watch<T>()` APIs instead.
- `TopProvider.providers` now accepts `List<MoProviderBuilder>` instead of
  provider's `List<SingleChildWidget>`. Use helpers such as
  `moNotifierProvider<T>((context) => T())`.
- Removed the `lazy` parameter from `LogicWidget` and `MoLcWidget`. It was a
  no-op: `init` reads `T` from the current scope, which forces immediate
  creation regardless of the flag.
- The module-level `coreContainerProvider` is gone. `TopProvider` now
  constructs a fresh `CoreContainer` per mount, and asserts that only one
  `TopProvider` is mounted at a time. Tests that mounted multiple roots in
  parallel must now mount them sequentially.

### Features
- `TopProvider` / `TopModel` / `top<T>()` for app-wide model access via a global key.
- `ExposedMixin` + top-level `find<T>()` / `findFuzzy()` for ad-hoc model lookup.
- `EventModel<T>` + `EventConsumerMixin` for partial top-model refresh by event.
- `ValueModel<T>` / `Value2Model` / `Value3Model` and matching
  `NoMoWidget` / `NoMo2Widget` / `NoMo3Widget` for trivial value-only state.
- `Mutable<T>` + `MutableWidget` and a family of typed extensions
  (`MutableStringExt`, `MutableBoolExt`, `MutableIntExt`, ...) for inline reactive values.
- Native MoLc provider primitives: `MoProvider`, `MoNotifierProvider`,
  `MoMultiProvider`, `MoProviderBuilder`, `moProvider`, `moProviderValue`,
  `moNotifierProvider`, `moNotifierProviderValue`, and `context.read/watch`.
- `WidgetLogic` and `MoLogic<T extends Model>` (paired with `MoLcWidget`).
- `SelectorMixin<T>` for `shouldRefresh` short-circuiting.
- `InitialBuilder.reassemble` callback hook.

### Fixes
- `WidgetModel.disposed` and `WidgetLogic.disposed` no longer probe element
  state. They return `true` only after `dispose()` has actually run (i.e.
  `_context` was nulled, or the parent `Model._disposed` flag was set).
  This avoids the deactivate/reactivate window where the previous
  `(DEFUNCT)` check — and a brief experiment with `!context.mounted` —
  would falsely report the model as disposed and silently drop refreshes.
- `WidgetModel.refresh<T>()` now propagates the type parameter when
  recursing into the parent model: `context.read<T>().refresh<T>()`.
- `MoLogic.refresh` declared with explicit `void` return; the type
  parameter was reverted to keep "refresh self" the only intent.
- `Init`, `LogicInit<T>`, `ModelLogicInit<T, R>` typedefs declared with
  explicit `void` return instead of bare `Function`.
- `EventConsumerMixin._id` now uses a monotonic counter instead of a
  bounded `Random().nextInt(10000)`, removing the birthday-paradox
  collision risk that could silently drop event listeners.
- `ExposedMixin` and `EventConsumerMixin` cache the `CoreContainer` they
  registered with, so dispose-time cleanup does not look up inherited
  ancestors while Flutter is deactivating the tree.
- `ModelWidget.value` now detaches `WidgetModel` context and removes
  `ExposedMixin` registrations when the widget unmounts without disposing the
  externally owned model.
- `ExposedMixin` now tracks expose owners instead of a raw counter, preserving
  multi-mount `.value` behavior without leaking stale container registrations.
- `ModelWidget.value` now detaches `EventConsumerMixin` listeners when the
  widget unmounts without disposing the externally owned model.
- `TopProvider` now keeps its `GlobalKey` on the mounted state and exposes the
  active state through a single current pointer, avoiding a module-level global
  key collision path while preserving `top<T>()`.
- `BuildContext.read<T>()` now includes a hint that dispose-time ancestor lookup
  is unsafe.
- `EventModel.refreshEvent` snapshots listeners before invoking callbacks, so
  a refresh that changes event subscriptions cannot mutate the listener map
  during iteration.
- `EventModel` now keys listeners by the event object instead of
  `event.toString()`, avoiding collisions between distinct events with the
  same string representation.
- `ExposedMixin.find<T>()` now uses `Type` keys instead of stringified runtime
  type names; `findFuzzy(String)` remains available for string lookup.
- `ExposedMixin.topLogic` is deprecated and no longer prevents exposed cleanup
  during dispose, avoiding stale disposed logic instances in `find<T>()`.
- `Mutable._refreshMap` now keys on the `_MutableState` object directly
  instead of its `hashCode`, removing the rare hash-collision case where
  one widget's listener could overwrite another's.
- Lint cleanup: `_InitialBuilderState` → `InitialBuilderState`,
  `_MUTABLE_SIZE` → `_mutableSize`, raw `Set()` literals replaced with
  typed set literals, function-typed parameter syntax replaced with
  `void Function()` form, `!(this is X && y)` → `this is! X || !y`.

### Repo / tooling
- Added root `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- `.metadata` channel switched from `beta` to `stable`.
- Added `dev_dependencies: flutter_lints: ^5.0.0`.
- Added widget tests for `ModelWidget`, `LogicWidget`, `MoLcWidget`,
  native provider read/watch behavior, top models, exposed models, and event
  refresh.
- Example app: dropped unused `get` dependency, bumped SDK to Dart 3,
  bumped `flutter_lints` to `^5.0.0`.

## 0.1.6

- Synced from a previously released artifact; no new changelog was written
  at the time. See 0.2.0 for a retrospective summary of what was already
  shipping in this version.

## 0.0.2

- Initial public release.
