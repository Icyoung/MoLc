# MoLc

MoLc 是一个轻量 Flutter 状态管理与页面架构组件。它的核心目标不是替代某个
状态管理库的 API，而是把 Flutter 页面里的 **UI 状态 Model** 和 **业务逻辑 Logic**
拆开，并补齐真实工程中常见的跨组件通信、全局状态局部刷新、细粒度刷新等能力。

当前版本基于 Flutter 原生的 `InheritedWidget` / `InheritedNotifier` 实现，
不依赖 `provider`。

## 设计目标

MoLc 关注以下工程问题：

* **Model / Logic 分离**：Widget 只负责声明 UI，状态放在 Model，业务动作放在 Logic。
* **上下文树访问补全**：子节点访问父级对象可以使用 `context.read<T>()` /
  `context.watch<T>()`；`top<T>()` 用于直接访问顶层全局 Model / repo，也适合框架级、
  非 widget 体系代码调用；
  `ExposedMixin` + `find<T>()` 成对用于非子节点访问父、父访问子、兄弟组件访问或活跃对象查找。
* **逻辑复用**：Logic 可以脱离 Widget 组织业务行为，也可以按需暴露给其他组件调用。
* **精准刷新**：Model 可以通过 `SelectorMixin` 决定是否刷新。
* **全局状态局部刷新**：TopModel 可以按事件刷新指定消费者，避免全局 Model 更新导致整棵 App rebuild。
* **颗粒刷新**：`Mutable<T>` 可以实现接近 GetX / mutableStateOf 的局部响应式刷新。

## 安装

```yaml
dependencies:
  molc: ^0.2.1
```

```dart
import 'package:molc/molc.dart';
```

## 快速开始

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

`refresh()` 会触发 Model 的 `notifyListeners()`，刷新依赖当前 Model 的 UI。

## 核心概念

### Model

`Model` 用来保存 Widget 状态。

```dart
class PageModel extends Model {
  int selectedIndex = 0;
  bool loading = false;
}
```

更新状态后调用：

```dart
model.refresh(() {
  model.selectedIndex = 1;
});
```

如果 Model 需要访问当前 widget 的 `BuildContext`，使用 `WidgetModel`：

```dart
class PageModel extends WidgetModel {
  String get title => Localizations.localeOf(context).toString();
}
```

`WidgetModel.context` 只在 Model 挂载到 `ModelWidget` / `MoLcWidget` 时有效。
当 widget 从树上移除时，MoLc 会 detach 这个 context。

### Logic

`Logic` 用来放请求、跳转、事件处理、业务协调等行为。

```dart
class RequestLogic extends Logic {
  Future<void> load(PageModel model) async {
    // request data
    model.refresh();
  }
}
```

如果 Logic 需要 context，使用 `WidgetLogic`：

```dart
class NavigatorLogic extends WidgetLogic {
  void close() {
    Navigator.of(context).pop();
  }
}
```

如果 Logic 与某个 Model 强绑定，使用 `MoLogic<T>`：

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

`MoLogic<T>` 适合页面级或组件级强关联逻辑。可复用 Logic 建议通过方法参数传入 Model，
避免业务逻辑过度依赖某个具体 UI 状态结构。

## 组件

### ModelWidget

只有 Model 时使用：

```dart
ModelWidget<PageModel>(
  create: (_) => PageModel(),
  builder: (context, model, child) {
    return Text('${model.selectedIndex}');
  },
);
```

外部持有 Model 时使用 `.value`：

```dart
final model = PageModel();

ModelWidget<PageModel>.value(
  value: model,
  builder: (context, model, child) => Text('${model.selectedIndex}'),
);
```

生命周期规则：

* `ModelWidget(create:)` 创建并负责 dispose Model。
* `ModelWidget.value` 不负责 dispose 外部 Model。
* 即使是 `.value`，MoLc 也会在 widget 卸载时 detach `WidgetModel.context`，
  并移除 `ExposedMixin` 的活跃注册。

### LogicWidget

只有 Logic 时使用：

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

`LogicWidget` 会创建 Logic，并在 widget 卸载时调用 `logic.dispose()`。

### MoLcWidget

同时需要 Model 和 Logic 时使用，这是最常用的组件。

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

## 原生 Provider 层

MoLc 提供了一层极薄的原生注入能力：

* `MoNotifierProvider<T extends ChangeNotifier>`
* `MoProvider<T>`
* `MoMultiProvider`
* `context.read<T>()`
* `context.watch<T>()`

`read<T>()` 只读取对象，不订阅刷新。

`watch<T>()` 会建立 inherited 依赖。当对应 `MoNotifierProvider` 的 notifier
触发通知时，使用 `watch<T>()` 的 widget 会 rebuild。

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

普通对象使用 `MoProvider`：

```dart
MoProvider<ApiClient>(
  create: (_) => ApiClient(),
  dispose: (client) => client.close(),
  child: const App(),
);
```

`MoMultiProvider` 中 provider 的顺序是从外到内：

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

靠前的 provider 在树的外层，靠后的 provider 可以在 `create` 中读取靠前的对象。

不要在 `dispose` 阶段通过 `context.read<T>()` 查找祖先。Flutter 会认为 deactivated
context 的祖先查找是不安全的。需要清理依赖时，应在对象创建、初始化或 attach 阶段先缓存。

## TopProvider 与 TopModel

Flutter 的 inherited 机制天然适合父节点向子节点传值。App 级状态通常需要放在
`MaterialApp` 之上，MoLc 用 `TopProvider` 统一承载这些顶级对象，并维护内部容器。

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

读取 TopModel：

```dart
final appModel = context.read<AppModel>();
final sameModel = top<AppModel>();
```

`top<T>()` 面向注册在 `TopProvider` 下的顶层全局 Model / repo，也适合框架级代码、
非 widget 体系代码、Logic / Model 方法、repo、外部单例 / service 等场景直接访问顶层对象。
调用方本身不需要被 MoLc 管理。

例如，HTTP 单例可以从顶层 AppConfigModel 读取 `baseUrl`：

```dart
class HttpClient {
  Uri buildUri(String path) {
    final config = top<AppConfigModel>();
    return Uri.parse('${config.baseUrl}$path');
  }
}
```

子节点 widget 也可以调用 `top<T>()`。相比 inherited-tree 查找，它会先跳到根
`TopProvider` context，因此访问顶层对象时路径更短。需要 UI 订阅 rebuild 时使用
`context.watch<T>()`；只需要非订阅读取时使用 `context.read<T>()` 或 `top<T>()`。

规则：

* 一个 App 同时只能挂载一个 `TopProvider`。
* `top<T>()` 只能在 `TopProvider` 已经挂载后使用。
* 不要在静态初始化、`runApp` 之前、或 `TopProvider` 实例尚未挂载时调用
  `top<T>()`。非 widget 调用方如需保护访问时机，可以先检查 `TopModel.isReady`。
* `top<T>()` 面向顶层全局 Model / repo；普通局部父级 provider 仍使用
  `context.read<T>()` / `context.watch<T>()`。
* 测试中需要先 `pumpWidget(const SizedBox.shrink())` 卸载旧树，再挂新 `TopProvider`。

## 全局 Model 局部刷新

全局 Model 更新时，如果直接刷新整个 TopModel，容易导致大范围 rebuild。
MoLc 用 `EventModel<T>` 和 `EventConsumerMixin` 做事件级局部刷新。

```dart
enum AppEvent { userChanged, themeChanged }

class AppModel extends TopModel with EventModel<AppEvent> {}

class ProfileModel extends Model with EventConsumerMixin {
  void init() {
    listenTopModelEvent(AppEvent.userChanged);
  }
}
```

触发事件：

```dart
top<AppModel>().refreshEvent(AppEvent.userChanged);
```

只监听 `AppEvent.userChanged` 的 Model 会刷新。

也可以提供自定义刷新函数和判断条件：

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

事件 key 使用事件对象本身的 `==` / `hashCode`，不是 `toString()`。
推荐使用 enum 或稳定的 value object。

## ExposedMixin

`InheritedWidget` 和 MoLc provider 层最适合子节点访问父节点：如果调用方是子节点，
优先使用 `context.read<T>()` 或 `context.watch<T>()`。

业务中有时需要非子节点访问：父组件访问子组件、兄弟组件互相访问，或者在非 Widget 层调用
当前活跃的 Logic。`ExposedMixin` 和 `find<T>()` 是成对使用的 API：
被查找的对象 mix in `ExposedMixin`，调用方再通过 `find<T>()` 查找当前活跃实例。

```dart
class DetailModel extends Model with ExposedMixin {
  void reload() {}
}
```

查找当前活跃实例：

```dart
find<DetailModel>()?.reload();
```

Logic 也可以暴露：

```dart
class DetailLogic extends Logic with ExposedMixin {
  void scrollToTop() {}
}

find<DetailLogic>()?.scrollToTop();
```

规则：

* `ExposedMixin` 和 `find<T>()` 应成对使用。
* `find<T>()` 返回当前活跃的最后一个 `T` 实例。
* 子节点访问父节点不要使用 `find<T>()`，应使用 `context.read<T>()` /
  `context.watch<T>()`。
* 对象从 `ModelWidget` / `LogicWidget` 卸载时会自动移除注册。
* `.value` 外部对象不会被 dispose，但也会在 widget 卸载时从活跃注册中移除。
* `findFuzzy(String)` 仍可用于字符串查找，但新代码推荐使用 `find<T>()`。

## SelectorMixin

`SelectorMixin<T>` 用于 Model 内部的精细化刷新判断。

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

`refresh()` 时，MoLc 会比较 `selectWith()` 的返回值。如果返回值没有变化，
Model 不会通知 UI 刷新。

注意：`selectWith()` 返回值需要有可靠的 `==` 语义。可以使用 record、tuple、
不可变 value object 等。

## Mutable

`Mutable<T>` 适合非常局部的响应式状态，例如列表项、计数器、局部开关。

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

在 `MutableWidget` builder 中读取 `count.value` 时，当前 `MutableWidget` 会被注册为依赖者。
写入 `count.value` 时，所有依赖它的 `MutableWidget` 会刷新。

设计备注：`Mutable` 内部的 scoped build observer 是刻意设计，不是残留的全局状态。
它利用 Flutter widget build 在单 isolate 上同步执行的模型，在 builder 中读取 `value`
时自动捕获当前 `MutableWidget` 并建立订阅，从而实现接近 GetX 的自动依赖追踪。
在 builder 外读取 `value` 只是普通读取，不会订阅任何 widget。

规则：

* 想订阅当前 widget 时，在 `MutableWidget` 的 builder 中同步读取 `Mutable.value`。
* 只需要当前值时，可以在 builder 外读取 `Mutable.value`。
* 可以在事件回调、异步回调中写入 `Mutable.value`。
* `MutableWidget` 支持嵌套，也支持多个 widget 监听同一个 `Mutable` 值。

## 简单值组件

如果只是需要一个临时 Model，可以使用 `NoMoWidget`：

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

也提供 `NoMo2Widget` 和 `NoMo3Widget`，分别对应 `Value2Model` 和 `Value3Model`。

## 推荐组织方式

页面级代码建议按这个思路拆分：

```text
page/
  user_page.dart      // Widget 和 MoLcWidget 装配
  user_model.dart     // UI 状态
  user_logic.dart     // 请求、跳转、业务动作
```

建议：

* 页面内部状态优先放在页面 Model。
* 请求、跳转、复杂业务流程放在 Logic。
* 跨页面共享状态放在 TopModel。
* 父访问子、兄弟访问、临时跨层调用才使用 ExposedMixin。
* 高频局部小状态可以使用 Mutable。
* 不要把所有状态都放进 TopModel，也不要把 `find<T>()` 当作默认数据流。

## 从 provider 迁移

MoLc 0.2.0 起不再依赖 `provider`，也不再从 `molc.dart` 导出 provider API。

旧写法：

```dart
ChangeNotifierProvider(
  create: (_) => AppModel(),
  child: const App(),
);
```

新写法：

```dart
MoNotifierProvider<AppModel>(
  create: (_) => AppModel(),
  child: const App(),
);
```

旧的 `TopProvider.providers` 如果使用 provider 的 `SingleChildWidget`：

```dart
TopProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppModel()),
  ],
  child: const App(),
);
```

迁移为：

```dart
TopProvider(
  providers: [
    moNotifierProvider<AppModel>((_) => AppModel()),
  ],
  child: const App(),
);
```

## API 一览

核心组件：

* `ModelWidget<T extends Model>`
* `LogicWidget<T extends Logic>`
* `MoLcWidget<T extends Model, R extends Logic>`
* `NoMoWidget<T>`
* `NoMo2Widget<A, B>`
* `NoMo3Widget<A, B, C>`

核心类型：

* `Model`
* `WidgetModel`
* `Logic`
* `WidgetLogic`
* `MoLogic<T extends Model>`
* `TopModel`

跨层能力：

* `TopProvider`
* `top<T extends TopModel>()`
* `ExposedMixin`
* `find<T extends ExposedMixin>()`
* `findFuzzy(String)`

刷新能力：

* `Model.refresh()`
* `SelectorMixin<T>`
* `EventModel<T>`
* `EventConsumerMixin`
* `Mutable<T>`
* `MutableWidget`

原生注入层：

* `MoProvider<T>`
* `MoNotifierProvider<T extends ChangeNotifier>`
* `MoMultiProvider`
* `moProvider<T>()`
* `moProviderValue<T>()`
* `moNotifierProvider<T>()`
* `moNotifierProviderValue<T>()`
* `context.read<T>()`
* `context.watch<T>()`

## 适用场景

MoLc 适合：

* 中小型到中大型 Flutter App；
* 页面状态较多、组件拆分较多的业务项目；
* 希望保留 Flutter 原生 Widget 思维，但减少状态和逻辑混杂的项目；
* 不想引入重型状态框架，但需要跨页面共享、局部刷新、逻辑复用的项目。

不建议把 MoLc 用成完全全局化的数据流。`top<T>()`、`find<T>()`、`Mutable<T>` 都是为
特定工程问题准备的工具，应按场景使用。
