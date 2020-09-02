import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'builder.dart';
import 'logic.dart';
import 'model.dart';
import 'type.dart';

class ModelWidget<T extends Model> extends StatelessWidget {
  const ModelWidget({
    Key key,
    @required this.create,
    @required this.builder,
    this.child,
  }) : super(key: key);

  final Create<T> create;
  final ModelWidgetBuilder<T> builder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: create,
      child: Consumer<T>(
        builder: (context, model, child) {
          if (model is WidgetModel) model.attach(context);
          return builder(context, model, child);
        },
        child: child,
      ),
    );
  }
}

class LogicWidget<T extends Logic> extends StatelessWidget {
  const LogicWidget({
    Key key,
    @required this.create,
    @required this.builder,
    this.init,
    this.lazy = false,
  }) : super(key: key);

  final Create<T> create;
  final LogicWidgetBuilder<T> builder;
  final LogicInit init;
  final bool lazy;

  @override
  Widget build(BuildContext context) {
    return Provider<T>(
      create: create,
      child: InitialBuilder(
        builder: (context) => builder(
          context,
          context.watch<T>(),
        ),
        initial: (context) => init?.call(
          context,
          context.read<T>(),
        ),
      ),
      dispose: (_, v) => v.dispose(),
      lazy: lazy,
    );
  }
}

class MoLcWidget<T extends Model, R extends Logic> extends StatelessWidget {
  const MoLcWidget({
    Key key,
    @required this.modelCreate,
    @required this.logicCreate,
    @required this.builder,
    this.init,
    this.child,
    this.lazy = false,
  }) : super(key: key);

  final Create<T> modelCreate;
  final Create<R> logicCreate;
  final ModelLogicInit<T, R> init;
  final ModelLogicWidgetBuilder<T, R> builder;
  final Widget child;
  final bool lazy;

  @override
  Widget build(BuildContext context) {
    return ModelWidget<T>(
      create: modelCreate,
      child: child,
      builder: (context, model, child) => LogicWidget<R>(
        create: logicCreate,
        builder: (context, logic) => builder(context, model, logic, child),
        init: (context, logic) => init?.call(context, model, logic),
        lazy: lazy,
      ),
    );
  }
}
