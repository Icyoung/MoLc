import 'package:flutter/widgets.dart';

typedef Create<T> = T Function(BuildContext context);

typedef Dispose<T> = void Function(T value);

typedef Init = void Function(BuildContext context, VoidCallback refresh);

typedef ModelWidgetBuilder<T> = Widget Function(BuildContext, T, Widget?);

typedef LogicWidgetBuilder<T> = Widget Function(BuildContext, T);

typedef ModelLogicWidgetBuilder<T, R> = Widget Function(
    BuildContext, T, R, Widget?);

/// Logic init signature. No `refresh` callback is exposed: state lives on
/// the Model, so triggering a rebuild from Logic goes through
/// `model.refresh()` (or `MoLogic.refresh`), not a widget-local setter.
typedef LogicInit<T> = void Function(BuildContext context, T logic);

/// Same convention as [LogicInit]: refresh goes through the Model.
typedef ModelLogicInit<T, R> = void Function(
    BuildContext context, T model, R logic);

typedef RefreshCallback = bool Function();
