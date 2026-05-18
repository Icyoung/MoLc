# MoLc

[简体中文](README.zh-CN.md)

MoLc is a lightweight Flutter state management and page-architecture package.
It separates **UI state Models** from **business Logic**, while filling common
engineering gaps such as cross-widget communication, app-level partial refresh,
fine-grained rebuild control, and local reactive values.

MoLc is implemented with Flutter's native `InheritedWidget` and
`InheritedNotifier` primitives. It does not depend on `provider`.

## Goals

MoLc focuses on practical Flutter app structure:

- **Model / Logic separation**: widgets declare UI, models hold UI state, and
  logic objects coordinate actions, requests, navigation, and side effects.
- **Context-tree access where Flutter is awkward**: descendants can access
  ancestors with `context.read<T>()` or `context.watch<T>()`. `top<T>()` gives
  direct access to app-root global models or repositories, including
  framework-level and non-widget code. `ExposedMixin` plus `find<T>()` is for
  non-descendant access such as parent-to-child, sibling, or active object
  lookup.
- **Logic reuse**: logic can be organized outside widgets and exposed only when
  another component needs to call it.
- **Selective rebuilds**: `SelectorMixin` lets a model decide whether a refresh
  should notify listeners.
- **App-level partial refresh**: `TopModel` can notify only consumers of a
  specific event instead of rebuilding every global-state consumer.
- **Local reactive values**: `Mutable<T>` provides GetX-like or
  `mutableStateOf`-like local reactive rebuilds.

## Installation

```yaml
dependencies:
  molc: ^0.2.1
```

```dart
import 'package:molc/molc.dart';
```

## Quick Start

```dart
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<_CounterModel, _CounterLogic>(
      modelCreate: (_) => _CounterModel(),
      logicCreate: (_) => _CounterLogic(),
      init: (_, model, logic) => logic.init(model),
      builder: (context, model, logic, child) {
        return Column(
          children: [
            Text('count: ${model.count}'),
            TextButton(
              onPressed: logic.increase,
              child: const Text('+1'),
            ),
          ],
        );
      },
    );
  }
}

class _CounterModel extends Model {
  int count = 0;
}

class _CounterLogic extends MoLogic<_CounterModel> {
  void init(_CounterModel model) {}

  void increase() {
    refresh(() {
      model.count++;
    });
  }
}
```

`refresh()` calls `notifyListeners()` on the model, which rebuilds widgets that
depend on that model.

## Core Concepts

### Model

`Model` stores widget state.

```dart
class PageModel extends Model {
  int selectedIndex = 0;
  bool loading = false;
}
```

Update state and notify listeners with:

```dart
model.refresh(() {
  model.selectedIndex = 1;
});
```

If a model needs the current widget `BuildContext`, extend `WidgetModel`:

```dart
class PageModel extends WidgetModel {
  String get title => Localizations.localeOf(context).toString();
}
```

`WidgetModel.context` is valid only while the model is attached to a
`ModelWidget` or `MoLcWidget`. MoLc detaches the context when the widget leaves
the tree.

### Logic

`Logic` stores requests, navigation, event handling, and business coordination.

```dart
class RequestLogic extends Logic {
  Future<void> load(PageModel model) async {
    // request data
    model.refresh();
  }
}
```

If logic needs `BuildContext`, extend `WidgetLogic`:

```dart
class NavigatorLogic extends WidgetLogic {
  void close() {
    Navigator.of(context).pop();
  }
}
```

If logic is tightly paired with one model type, extend `MoLogic<T>`:

```dart
class BoundPageLogic extends MoLogic<PageModel> {
  void init(PageModel model) {}

  void reload() {
    refresh(() {
      model.loading = true;
    });
  }
}
```

`MoLogic<T>` fits page-level or component-level logic. For reusable logic,
prefer passing models as method arguments instead of coupling the logic to one
specific UI state shape.

## Widgets

### ModelWidget

Use `ModelWidget` when a subtree only needs a model:

```dart
ModelWidget<PageModel>(
  create: (_) => PageModel(),
  builder: (context, model, child) {
    return Text('${model.selectedIndex}');
  },
);
```

Use `.value` when the model is owned externally:

```dart
final model = PageModel();

ModelWidget<PageModel>.value(
  value: model,
  builder: (context, model, child) => Text('${model.selectedIndex}'),
);
```

Lifecycle rules:

- `ModelWidget(create:)` creates and disposes the model.
- `ModelWidget.value` does not dispose the external model.
- Both constructors detach `WidgetModel.context` and remove active
  `ExposedMixin` registrations when unmounted.

### LogicWidget

Use `LogicWidget` when a subtree only needs logic:

```dart
class SubmitLogic extends Logic {
  void init() {}

  void submit() {}
}

LogicWidget<SubmitLogic>(
  create: (_) => SubmitLogic(),
  init: (context, logic) => logic.init(),
  builder: (context, logic) {
    return TextButton(
      onPressed: logic.submit,
      child: const Text('submit'),
    );
  },
);
```

`LogicWidget` creates the logic object and calls `logic.dispose()` on unmount.

### MoLcWidget

Use `MoLcWidget` when a subtree needs both model and logic:

```dart
MoLcWidget<PageModel, BoundPageLogic>(
  modelCreate: (_) => PageModel(),
  logicCreate: (_) => BoundPageLogic(),
  init: (_, model, logic) => logic.init(model),
  builder: (context, model, logic, child) {
    return Text('${model.selectedIndex}');
  },
);
```

If the logic extends `MoLogic<T>`, MoLc automatically connects it to the current
model. `MoLcWidget.value` also reconnects `MoLogic` when `modelValue` is
replaced with another model instance.

## Native Provider Layer

MoLc provides a small native dependency-injection layer:

- `MoNotifierProvider<T extends ChangeNotifier>`
- `MoProvider<T>`
- `MoMultiProvider`
- `context.read<T>()`
- `context.watch<T>()`

`read<T>()` reads a value without subscribing. `watch<T>()` creates an inherited
dependency and rebuilds when the matching `MoNotifierProvider` notifies.

```dart
MoNotifierProvider<PageModel>(
  create: (_) => PageModel(),
  child: Builder(
    builder: (context) {
      final model = context.watch<PageModel>();
      return Text('${model.selectedIndex}');
    },
  ),
);
```

Use `MoProvider` for plain objects:

```dart
MoProvider<ApiClient>(
  create: (_) => ApiClient(),
  dispose: (client) => client.close(),
  child: const App(),
);
```

Providers in `MoMultiProvider` are applied from outer to inner:

```dart
MoMultiProvider(
  providers: [
    moProvider<ApiClient>((_) => ApiClient()),
    moProvider<UserRepository>((context) {
      return UserRepository(context.read<ApiClient>());
    }),
  ],
  child: const App(),
);
```

Earlier providers are outside later providers, so later `create` callbacks can
read earlier values.

Do not call `context.read<T>()` during `dispose` to look up ancestors. Flutter
does not allow ancestor lookup from a deactivated context. Cache cleanup
dependencies during creation, initialization, or attach instead.

## TopProvider and TopModel

Flutter's inherited mechanism naturally passes data from parents to children.
App-level state usually belongs above `MaterialApp`. `TopProvider` holds those
top-level objects and MoLc's internal container.

```dart
void main() {
  runApp(
    TopProvider(
      providers: [
        moNotifierProvider<AppModel>((_) => AppModel()),
      ],
      child: const MaterialApp(
        home: HomePage(),
      ),
    ),
  );
}

class AppModel extends TopModel {}
```

Read top models with either context or the context-free `top<T>()` helper:

```dart
final appModel = context.read<AppModel>();
final sameModel = top<AppModel>();
```

Use `top<T>()` for app-root global models or repositories registered under
`TopProvider`. It is also useful from framework-level code, non-widget code,
logic/model methods, repositories, external singletons/services, or other places
that should directly reach a top-level object. The caller itself does not need
to be managed by MoLc.

For example, an HTTP singleton can read `baseUrl` from an app-level config
model:

```dart
class HttpClient {
  Uri buildUri(String path) {
    final config = top<AppConfigModel>();
    return Uri.parse('${config.baseUrl}$path');
  }
}
```

Descendant widgets can also call `top<T>()`. Compared with inherited-tree lookup,
it jumps to the root `TopProvider` context first, so it can be a shorter direct
lookup for top-level objects. Use `context.watch<T>()` when the widget should
subscribe to rebuilds; use `context.read<T>()` or `top<T>()` when it only needs a
non-subscribing read.

Rules:

- Only one `TopProvider` can be mounted at a time.
- `top<T>()` can be called only after a `TopProvider` is mounted.
- Do not call `top<T>()` during static initialization, before `runApp`, or
  before the `TopProvider` instance has mounted. Use `TopModel.isReady` if a
  non-widget caller needs to guard access.
- `top<T>()` is for top-level global models or repositories. For ordinary local
  parent providers, keep using `context.read<T>()` / `context.watch<T>()`.
- In widget tests, tear down the previous root with
  `pumpWidget(const SizedBox.shrink())` before mounting another `TopProvider`.

## App-Level Partial Refresh

Refreshing a full app-level model can rebuild too much UI. MoLc uses
`EventModel<T>` and `EventConsumerMixin` for event-scoped refresh.

```dart
enum AppEvent { userChanged, themeChanged }

class AppModel extends TopModel with EventModel<AppEvent> {}

class ProfileModel extends Model with EventConsumerMixin {
  void init() {
    listenTopModelEvent(AppEvent.userChanged);
  }
}
```

Trigger an event:

```dart
top<AppModel>().refreshEvent(AppEvent.userChanged);
```

Only models listening to `AppEvent.userChanged` refresh.

You can provide a custom refresh callback and condition:

```dart
listenTopModelEvent(
  AppEvent.userChanged,
  test: () => shouldUpdate,
  refresh: () {
    reloadLocalData();
    refresh();
  },
);
```

Event keys use the event object's `==` and `hashCode`, not `toString()`.
Prefer enums or stable value objects.

## ExposedMixin

`InheritedWidget` and MoLc's provider layer are best for child-to-parent access:
if the caller is a descendant, use `context.read<T>()` or `context.watch<T>()`.

Some apps also need non-descendant access: a parent needs to call a child,
sibling components need to reach each other, or non-widget layers need to call
the currently active logic. `ExposedMixin` and `find<T>()` are the paired API
for that case: mix in `ExposedMixin` on the object that may be found, then use
`find<T>()` to look up the last active instance.

```dart
class DetailModel extends Model with ExposedMixin {
  void reload() {}
}
```

Find the current active instance:

```dart
find<DetailModel>()?.reload();
```

Logic can be exposed too:

```dart
class DetailLogic extends Logic with ExposedMixin {
  void scrollToTop() {}
}

find<DetailLogic>()?.scrollToTop();
```

Rules:

- `ExposedMixin` and `find<T>()` are intended to be used together.
- `find<T>()` returns the last active registered instance of type `T`.
- Do not use `find<T>()` for normal child-to-parent reads; use
  `context.read<T>()` or `context.watch<T>()` instead.
- Objects are removed from the active registry when their `ModelWidget` or
  `LogicWidget` unmounts.
- External `.value` objects are not disposed, but they are removed from the
  active registry on unmount.
- `findFuzzy(String)` remains available for string-based lookup, but new code
  should prefer the type-safe `find<T>()`.

## SelectorMixin

`SelectorMixin<T>` lets a model decide whether a refresh should notify
listeners.

```dart
class PageModel extends Model with SelectorMixin<(int, String)> {
  int count = 0;
  String keyword = '';
  bool loading = false;

  @override
  (int, String) selectWith() {
    return (count, keyword);
  }
}
```

When `refresh()` runs, MoLc compares the current `selectWith()` value with the
previous one. If the value did not change, the model does not notify UI
listeners.

The selected value must have reliable `==` semantics. Dart records, tuples, and
immutable value objects are good choices.

## Mutable

`Mutable<T>` is useful for very local reactive state such as list items,
counters, and local switches.

```dart
final count = 0.mt;

MutableWidget(
  (context) {
    return Row(
      children: [
        Text('${count.value}'),
        TextButton(
          onPressed: () {
            count.value += 1;
          },
          child: const Text('+1'),
        ),
      ],
    );
  },
);
```

Reading `count.value` inside a `MutableWidget` builder registers that widget as
a subscriber. Writing `count.value` refreshes every `MutableWidget` that
depends on it.

Design note: the scoped build observer inside `Mutable` is intentional. It
relies on Flutter widget builds running synchronously on one isolate. When a
builder reads `value`, `Mutable` captures the currently building
`MutableWidget` and creates an automatic subscription, giving MoLc GetX-like
dependency tracking. Reads outside a `MutableWidget` builder are plain reads
and do not subscribe anything.

Rules:

- Read `Mutable.value` synchronously inside a `MutableWidget` builder when you
  want to subscribe that widget.
- Read `Mutable.value` outside a builder when you only need the current value.
- Write `Mutable.value` from event callbacks, async callbacks, or other normal
  application code.
- `MutableWidget` supports nesting and multiple widgets subscribing to the same
  `Mutable`.

## Simple Value Widgets

Use `NoMoWidget` when you only need a temporary model:

```dart
NoMoWidget<int>(
  value: 0,
  builder: (context, model, child) {
    return TextButton(
      onPressed: () {
        model.refresh(() {
          model.value++;
        });
      },
      child: Text('${model.value}'),
    );
  },
);
```

`NoMo2Widget` and `NoMo3Widget` provide the matching wrappers for
`Value2Model` and `Value3Model`.

## Recommended Structure

For page-level code, prefer a structure like this:

```text
page/
  user_page.dart      // Widget and MoLcWidget wiring
  user_model.dart     // UI state
  user_logic.dart     // requests, navigation, business actions
```

Recommendations:

- Keep page-local UI state in the page model.
- Put requests, navigation, and complex workflows in logic.
- Put cross-page shared state in `TopModel`.
- Use `ExposedMixin` only for parent-to-child, sibling, or temporary
  cross-layer calls.
- Use `Mutable` for small high-frequency local state.
- Do not put all state into `TopModel`.
- Do not treat `find<T>()` as the default data flow.

## Migrating from provider

MoLc 0.2.0 and later no longer depend on `provider`, and `molc.dart` no longer
exports provider APIs.

Old code:

```dart
ChangeNotifierProvider(
  create: (_) => AppModel(),
  child: const App(),
);
```

New code:

```dart
MoNotifierProvider<AppModel>(
  create: (_) => AppModel(),
  child: const App(),
);
```

Old `TopProvider.providers` using provider's `SingleChildWidget`:

```dart
TopProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppModel()),
  ],
  child: const App(),
);
```

Migrate to:

```dart
TopProvider(
  providers: [
    moNotifierProvider<AppModel>((_) => AppModel()),
  ],
  child: const App(),
);
```

## API Overview

Core widgets:

- `ModelWidget<T extends Model>`
- `LogicWidget<T extends Logic>`
- `MoLcWidget<T extends Model, R extends Logic>`
- `NoMoWidget<T>`
- `NoMo2Widget<A, B>`
- `NoMo3Widget<A, B, C>`

Core types:

- `Model`
- `WidgetModel`
- `Logic`
- `WidgetLogic`
- `MoLogic<T extends Model>`
- `TopModel`

Cross-layer tools:

- `TopProvider`
- `top<T extends TopModel>()`
- `ExposedMixin`
- `find<T extends ExposedMixin>()`
- `findFuzzy(String)`

Refresh tools:

- `Model.refresh()`
- `SelectorMixin<T>`
- `EventModel<T>`
- `EventConsumerMixin`
- `Mutable<T>`
- `MutableWidget`

Native injection layer:

- `MoProvider<T>`
- `MoNotifierProvider<T extends ChangeNotifier>`
- `MoMultiProvider`
- `moProvider<T>()`
- `moProviderValue<T>()`
- `moNotifierProvider<T>()`
- `moNotifierProviderValue<T>()`
- `context.read<T>()`
- `context.watch<T>()`

## Fit

MoLc fits:

- small to medium Flutter apps;
- larger business apps with many page states and components;
- projects that want to keep Flutter's native widget model while reducing
  mixed UI state and business logic;
- projects that do not want a heavy state framework but still need shared
  state, partial refresh, and reusable logic.

MoLc should not be used as a fully globalized data flow. `top<T>()`,
`find<T>()`, and `Mutable<T>` solve specific engineering problems and should be
used intentionally.
