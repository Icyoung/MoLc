import 'package:flutter/widgets.dart';

/// Factory function that creates an instance given a [BuildContext].
typedef Create<T> = T Function(BuildContext context);

/// Cleanup function called when a provider disposes its value.
typedef Dispose<T> = void Function(T value);

/// Initialization callback that receives a refresh function.
typedef Init = void Function(BuildContext context, VoidCallback refresh);

/// Builder signature for [ModelWidget].
typedef ModelWidgetBuilder<T> = Widget Function(BuildContext, T, Widget?);

/// Builder signature for [LogicWidget].
typedef LogicWidgetBuilder<T> = Widget Function(BuildContext, T);

/// Builder signature for [MoLcWidget].
typedef ModelLogicWidgetBuilder<T, R> = Widget Function(
    BuildContext, T, R, Widget?);

/// Logic init signature. No `refresh` callback is exposed: state lives on
/// the Model, so triggering a rebuild from Logic goes through
/// `model.refresh()` (or `MoLogic.refresh`), not a widget-local setter.
typedef LogicInit<T> = void Function(BuildContext context, T logic);

/// Same convention as [LogicInit]: refresh goes through the Model.
typedef ModelLogicInit<T, R> = void Function(
    BuildContext context, T model, R logic);

/// Callback returned by a refreshable widget to check if it is still mounted.
/// Returns `true` if the widget should remain subscribed.
typedef RefreshCallback = bool Function();