import 'package:flutter/material.dart';
import 'package:molc/src/molc/exposed.dart';
import 'package:provider/provider.dart';

import 'builder.dart';
import 'logic.dart';
import 'model.dart';
import 'type.dart';

class ModelWidget<T extends Model> extends StatelessWidget {
  Create<T>? create;
  T? value;
  final ModelWidgetBuilder<T> builder;
  final Widget? child;

  ModelWidget({
    Key? key,
    required Create<T> create,
    required this.builder,
    this.child,
  })  : this.create = create,
        super(key: key);

  ModelWidget.value(
      {Key? key, required T value, required this.builder, this.child})
      : this.value = value,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final consumer = Consumer<T>(
      builder: (context, model, child) {
        ///attached prevent muti
        if (model is WidgetModel && !model.attached) model.attach(context);
        if (model is ExposedMixin && !(model as ExposedMixin).exposed)
          (model as ExposedMixin).saveSelf(context);
        return builder(context, model, child);
      },
      child: child,
    );
    if (value != null) {
      return ChangeNotifierProvider.value(
        value: value!,
        child: consumer,
      );
    }
    return ChangeNotifierProvider<T>(
      create: create!,
      child: consumer,
    );
  }
}

class LogicWidget<T extends Logic> extends StatelessWidget {
  const LogicWidget({
    Key? key,
    required this.create,
    required this.builder,
    this.init,
    this.lazy = false,
  }) : super(key: key);

  final Create<T> create;
  final LogicWidgetBuilder<T> builder;
  final LogicInit<T>? init;
  final bool lazy;

  @override
  Widget build(BuildContext context) {
    return Provider<T>(
      create: create,
      child: InitialBuilder(builder: (context) {
        final logic = context.read<T>();
        return builder(context, logic);
      }, initial: (context, _) {
        final logic = context.read<T>();
        if (logic is WidgetLogic) logic.attach(context);
        if (logic is ExposedMixin) (logic as ExposedMixin).saveSelf(context);
        return init?.call(context, logic);
      }),
      dispose: (context, logic) => logic.dispose(),
      lazy: lazy,
    );
  }
}

class MoLcWidget<T extends Model, R extends Logic> extends StatelessWidget {
  Create<T>? modelCreate;
  T? modelValue;
  final Create<R> logicCreate;
  final ModelLogicInit<T, R>? init;
  final ModelLogicWidgetBuilder<T, R> builder;
  final Widget? child;
  final bool lazy;

  MoLcWidget(
      {Key? key,
      required Create<T> modelCreate,
      required this.logicCreate,
      required this.builder,
      this.child,
      this.init,
      this.lazy = false,
      this.modelValue})
      : this.modelCreate = modelCreate,
        super(key: key);

  MoLcWidget.value({
    Key? key,
    required T modelValue,
    required this.logicCreate,
    required this.builder,
    this.child,
    this.init,
    this.lazy = false,
  })  : this.modelValue = modelValue,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final logicWidgetBuilder = (context, model, child) => LogicWidget<R>(
          create: logicCreate,
          builder: (context, logic) => builder(context, model, logic, child),
          init: (context, logic) {
            if (logic is MoLogic) logic.contact(model);
            init?.call(context, model, logic);
          },
          lazy: lazy,
        );
    if (modelValue != null) {
      return ModelWidget.value(
        value: modelValue!,
        child: child,
        builder: logicWidgetBuilder,
      );
    }
    return ModelWidget<T>(
      create: modelCreate!,
      child: child,
      builder: logicWidgetBuilder,
    );
  }
}

/// NO Model class Widget, for simple model
class NoMoWidget<T> extends StatelessWidget {
  final T value;

  final ModelWidgetBuilder<ValueModel<T>> builder;

  NoMoWidget({
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ValueModel<T>(value: value),
      child: Consumer<ValueModel<T>>(
        builder: (context, model, child) {
          return builder(context, model, child);
        },
      ),
    );
  }
}

class NoMo2Widget<A, B> extends StatelessWidget {
  final A value;
  final B value2;

  final ModelWidgetBuilder<Value2Model<A, B>> builder;

  NoMo2Widget({
    required this.value,
    required this.value2,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Value2Model<A, B>(
        value: value,
        value2: value2,
      ),
      child: Consumer<Value2Model<A, B>>(
        builder: (context, model, child) {
          return builder(context, model, child);
        },
      ),
    );
  }
}

class NoMo3Widget<A, B, C> extends StatelessWidget {
  final A value;
  final B value2;
  final C value3;

  final ModelWidgetBuilder<Value3Model<A, B, C>> builder;

  NoMo3Widget({
    required this.value,
    required this.value2,
    required this.value3,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Value3Model<A, B, C>(
        value: value,
        value2: value2,
        value3: value3,
      ),
      child: Consumer<Value3Model<A, B, C>>(
        builder: (context, model, child) {
          return builder(context, model, child);
        },
      ),
    );
  }
}
