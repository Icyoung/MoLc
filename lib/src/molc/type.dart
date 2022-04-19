import 'package:flutter/material.dart';

typedef Init = Function(BuildContext, VoidCallback refresh);

typedef ModelWidgetBuilder<T> = Widget Function(BuildContext, T, Widget?);

typedef LogicWidgetBuilder<T> = Widget Function(BuildContext, T);

typedef ModelLogicWidgetBuilder<T, R> = Widget Function(
    BuildContext, T, R, Widget?);

typedef LogicInit<T> = Function(BuildContext, T);

typedef ModelLogicInit<T, R> = Function(BuildContext, T, R);

typedef RefreshCallback = bool Function();
