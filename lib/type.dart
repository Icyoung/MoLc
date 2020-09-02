import 'package:flutter/material.dart';

typedef Init<T> = Function(BuildContext context);

typedef ModelWidgetBuilder<T> = Widget Function(
    BuildContext context, T, Widget child);

typedef LogicWidgetBuilder<T> = Widget Function(BuildContext context, T);

typedef ModelLogicWidgetBuilder<T, R> = Widget Function(
    BuildContext context, T, R, Widget child);

typedef LogicInit<T> = Function(BuildContext context, T);

typedef ModelLogicInit<T, R> = Function(BuildContext context, T, R);
