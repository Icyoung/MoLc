import 'package:flutter/material.dart';
import 'package:molc/src/molc/part.dart';
import 'package:provider/provider.dart';

import 'builder.dart';
import 'logic.dart';
import 'model.dart';
import 'type.dart';

class ModelWidget<T extends Model> extends StatelessWidget {
  ModelWidget({
    Key? key,
    this.create,
    required this.builder,
    this.child,
    this.value,
  })  : assert(create != null || value != null),
        super(key: key);

  final Create<T>? create;
  final ModelWidgetBuilder<T> builder;
  final Widget? child;
  T? value;

  ModelWidget.value(
      {Key? key, required T value, required this.builder, this.child})
      : this.value = value,
        this.create = ((_) => value),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (value != null) {
      return ChangeNotifierProvider.value(
        value: value!,
        child: Consumer<T>(
          builder: (context, model, child) {
            if (model is WidgetModel) model.attach(context);
            if (model is PartModel) model.saveSelf(context);
            return builder(context, model, child);
          },
          child: child,
        ),
      );
    }
    return ChangeNotifierProvider<T>(
      create: create!,
      child: Consumer<T>(
        builder: (context, model, child) {
          if (model is WidgetModel && !model.attached) model.attach(context);
          if (model is PartModel) model.saveSelf(context);
          return builder(context, model, child);
        },
        child: child,
      ),
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
      child: InitialBuilder(
        builder: (context) => builder(
          context,
          context.watch<T>(),
        ),
        initial: (context, _) => init?.call(
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
  MoLcWidget(
      {Key? key,
      this.modelCreate,
      required this.logicCreate,
      required this.builder,
      this.child,
      this.init,
      this.lazy = false,
      this.modelValue})
      : assert(modelCreate != null || modelValue != null),
        super(key: key);

  /// 目前dart泛型并不支持构造器，暂时将value放入默认构造器
  MoLcWidget.modelValue({
    Key? key,
    required T modelValue,
    required this.logicCreate,
    required this.builder,
    this.child,
    this.init,
    this.lazy = false,
  })  : this.modelValue = modelValue,
        modelCreate = ((_) => modelValue),
        super(key: key);

  final Create<T>? modelCreate;
  final Create<R> logicCreate;
  final ModelLogicInit<T, R>? init;
  final ModelLogicWidgetBuilder<T, R> builder;
  final Widget? child;
  final bool lazy;
  T? modelValue;

  @override
  Widget build(BuildContext context) {
    if (modelValue != null) {
      return ModelWidget(
        value: modelValue!,
        child: child,
        builder: (context, model, child) => LogicWidget<R>(
          create: logicCreate,
          builder: (context, logic) {
            if (model is PageModel) model.contact(logic);
            return builder(context, model as T, logic, child);
          },
          init: (context, logic) => init?.call(context, model as T, logic),
          lazy: lazy,
        ),
      );
    }
    return ModelWidget<T>(
      create: modelCreate,
      child: child,
      builder: (context, model, child) => LogicWidget<R>(
        create: logicCreate,
        builder: (context, logic) {
          if (model is PageModel) model.contact(logic);
          return builder(context, model, logic, child);
        },
        init: (context, logic) => init?.call(context, model, logic),
        lazy: lazy,
      ),
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
