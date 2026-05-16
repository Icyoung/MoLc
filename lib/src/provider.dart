import 'package:flutter/widgets.dart';

import 'type.dart';

typedef MoProviderBuilder = Widget Function(Widget child);

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

extension MoReadContext on BuildContext {
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

extension MoWatchContext on BuildContext {
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

MoProviderBuilder moProviderValue<T>(T value) {
  return (child) => MoProvider<T>.value(
        value: value,
        child: child,
      );
}

MoProviderBuilder moNotifierProvider<T extends ChangeNotifier>(
  Create<T> create,
) {
  return (child) => MoNotifierProvider<T>(
        create: create,
        child: child,
      );
}

MoProviderBuilder moNotifierProviderValue<T extends ChangeNotifier>(T value) {
  return (child) => MoNotifierProvider<T>.value(
        value: value,
        child: child,
      );
}
