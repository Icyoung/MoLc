import 'package:flutter/widgets.dart';

import 'type.dart';

/// Wraps a child widget with a provider.
typedef MoProviderBuilder = Widget Function(Widget child);

/// An [InheritedNotifier] that provides a typed value to descendant widgets.
///
/// This is the core of MoLc's dependency injection layer. Use [MoReadContext.read]
/// to read without subscribing, or [MoWatchContext.watch] to rebuild on changes.
class MoScope<T> extends InheritedNotifier<Listenable> {
  final T value;

  const MoScope({
    super.key,
    required this.value,
    super.notifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant MoScope<T> oldWidget) {
    return !identical(value, oldWidget.value) ||
        super.updateShouldNotify(oldWidget);
  }
}

/// Extension on [BuildContext] to read values from the nearest [MoScope].
///
/// [read] returns the value **without** subscribing to refresh notifications.
/// Use this for one-time lookups (e.g. in event handlers, `init` callbacks).
///
/// To subscribe to changes and rebuild when the value updates, use
/// [MoWatchContext.watch] instead.
///
/// Throws if no [MoScope<T>] is found in the ancestor tree.
extension MoReadContext on BuildContext {
  /// Read the value from the nearest [MoScope<T>] without subscribing.
  T read<T>() {
    final element = getElementForInheritedWidgetOfExactType<MoScope<T>>();
    final widget = element?.widget;
    if (widget is MoScope<T>) {
      return widget.value;
    }
    throw FlutterError.fromParts([
      ErrorSummary('No MoLc provider found for $T.'),
      ErrorDescription(
        'read<$T>() was called with a BuildContext that does not contain a '
        'MoScope<$T>.',
      ),
      ErrorHint(
        'Do not call read<$T>() from dispose after the context has been '
        'deactivated. Cache dependencies before dispose if cleanup needs them.',
      ),
    ]);
  }
}

/// Extension on [BuildContext] to watch values from the nearest [MoScope].
///
/// [watch] returns the value **and** subscribes the current widget to refresh
/// notifications. When the [MoNotifierProvider] notifies its listeners,
/// widgets that called [watch] will rebuild.
///
/// For one-time lookups that don't need rebuilds, use [MoReadContext.read] instead.
///
/// Throws if no [MoScope<T>] is found in the ancestor tree.
extension MoWatchContext on BuildContext {
  /// Watch the value from the nearest [MoScope<T>], subscribing to refresh.
  T watch<T>() {
    final scope = dependOnInheritedWidgetOfExactType<MoScope<T>>();
    if (scope != null) {
      return scope.value;
    }
    throw FlutterError.fromParts([
      ErrorSummary('No MoLc provider found for $T.'),
      ErrorDescription(
        'watch<$T>() was called with a BuildContext that does not contain a '
        'MoScope<$T>.',
      ),
    ]);
  }
}

/// A provider that makes a plain (non-notify) value available to descendants.
///
/// Use this for objects that don't trigger UI rebuilds on their own —
/// e.g. repositories, API clients, configuration objects.
///
/// **Named constructor** — creates and optionally disposes the value:
///
///     MoProvider<ApiClient>(
///       create: (_) => ApiClient(),
///       dispose: (client) => client.close(),
///       child: const App(),
///     );
///
/// **[value] constructor** — uses an externally-held value without disposing it:
///
///     MoProvider<ApiClient>.value(
///       value: sharedClient,
///       child: const App(),
///     );
class MoProvider<T> extends StatefulWidget {
  final Create<T>? create;
  final T? value;
  final Dispose<T>? dispose;
  final Widget child;
  final bool _ownsValue;

  const MoProvider({
    super.key,
    required this.create,
    this.dispose,
    required this.child,
  })  : value = null,
        _ownsValue = true;

  const MoProvider.value({
    super.key,
    required this.value,
    required this.child,
  })  : create = null,
        dispose = null,
        _ownsValue = false;

  @override
  State<MoProvider<T>> createState() => _MoProviderState<T>();
}

class _MoProviderState<T> extends State<MoProvider<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget._ownsValue ? widget.create!(context) : widget.value as T;
  }

  @override
  void didUpdateWidget(covariant MoProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._ownsValue && !identical(widget.value, oldWidget.value)) {
      _value = widget.value as T;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MoScope<T>(
      value: _value,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (widget._ownsValue) {
      widget.dispose?.call(_value);
    }
    super.dispose();
  }
}

/// A provider that makes a [ChangeNotifier] value available and triggers
/// rebuilds in descendants when the notifier fires notifications.
///
/// Use this for state objects that change over time and need to update the UI.
/// [Model] extends [ChangeNotifier], so it works with [MoNotifierProvider].
///
/// **Named constructor** — creates and disposes the notifier:
///
///     MoNotifierProvider<PageModel>(
///       create: (_) => PageModel(),
///       child: Builder(
///         builder: (context) {
///           final model = context.watch<PageModel>();
///           return Text('${model.count}');
///         },
///       ),
///     );
///
/// **[value] constructor** — uses an externally-held notifier without disposing it:
///
///     MoNotifierProvider<PageModel>.value(
///       value: externalModel,
///       child: ...,
///     );
class MoNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final Create<T>? create;
  final T? value;
  final Widget child;
  final bool _ownsValue;

  const MoNotifierProvider({
    super.key,
    required this.create,
    required this.child,
  })  : value = null,
        _ownsValue = true;

  const MoNotifierProvider.value({
    super.key,
    required this.value,
    required this.child,
  })  : create = null,
        _ownsValue = false;

  @override
  State<MoNotifierProvider<T>> createState() => _MoNotifierProviderState<T>();
}

class _MoNotifierProviderState<T extends ChangeNotifier>
    extends State<MoNotifierProvider<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget._ownsValue ? widget.create!(context) : widget.value as T;
  }

  @override
  void didUpdateWidget(covariant MoNotifierProvider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._ownsValue && !identical(widget.value, oldWidget.value)) {
      _value = widget.value as T;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MoScope<T>(
      value: _value,
      notifier: _value,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (widget._ownsValue) {
      _value.dispose();
    }
    super.dispose();
  }
}

/// A widget that stacks multiple providers from outer to inner.
///
/// Providers are applied in the order they appear in the list — the first
/// provider is the outermost, and later providers can read earlier ones
/// in their [Create] callbacks.
///
///     MoMultiProvider(
///       providers: [
///         moProvider<ApiClient>((_) => ApiClient()),
///         moProvider<UserRepository>((context) {
///           return UserRepository(context.read<ApiClient>());
///         }),
///       ],
///       child: const App(),
///     );
///
/// **Warning:** Do not call [MoReadContext.read] from a [Dispose] callback
/// after the context has been deactivated. Cache dependencies during
/// initialization if cleanup needs them.
class MoMultiProvider extends StatelessWidget {
  final List<MoProviderBuilder> providers;
  final Widget child;

  const MoMultiProvider({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return providers.reversed.fold<Widget>(
      child,
      (child, provider) => provider(child),
    );
  }
}

/// Create a [MoProvider] builder function for [MoMultiProvider].
///
///     moProvider<ApiClient>((_) => ApiClient())
MoProviderBuilder moProvider<T>(
  Create<T> create, {
  Dispose<T>? dispose,
}) {
  return (child) => MoProvider<T>(
        create: create,
        dispose: dispose,
        child: child,
      );
}

/// Create a [MoProvider.value] builder function for [MoMultiProvider].
MoProviderBuilder moProviderValue<T>(T value) {
  return (child) => MoProvider<T>.value(
        value: value,
        child: child,
      );
}

/// Create a [MoNotifierProvider] builder function for [MoMultiProvider].
MoProviderBuilder moNotifierProvider<T extends ChangeNotifier>(
  Create<T> create,
) {
  return (child) => MoNotifierProvider<T>(
        create: create,
        child: child,
      );
}

/// Create a [MoNotifierProvider.value] builder function for [MoMultiProvider].
MoProviderBuilder moNotifierProviderValue<T extends ChangeNotifier>(T value) {
  return (child) => MoNotifierProvider<T>.value(
        value: value,
        child: child,
      );
}
