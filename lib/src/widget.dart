import 'package:flutter/widgets.dart';

import 'builder.dart';
import 'event.dart';
import 'exposed.dart';
import 'logic.dart';
import 'model.dart';
import 'provider.dart';
import 'type.dart';

@immutable
class ModelWidget<T extends Model> extends StatelessWidget {
  final Create<T>? create;
  final T? value;
  final ModelWidgetBuilder<T> builder;
  final Widget? child;

  const ModelWidget({
    super.key,
    required this.create,
    required this.builder,
    this.child,
  }) : value = null;

  const ModelWidget.value({
    super.key,
    required this.value,
    required this.builder,
    this.child,
  }) : create = null;

  @override
  Widget build(BuildContext context) {
    final consumer = _ModelConsumer<T>(
      builder: builder,
      child: child,
    );
    final v = value;
    if (v != null) {
      return MoNotifierProvider<T>.value(
        value: v,
        child: consumer,
      );
    }
    return MoNotifierProvider<T>(
      create: create!,
      child: consumer,
    );
  }
}

class _ModelConsumer<T extends Model> extends StatefulWidget {
  final ModelWidgetBuilder<T> builder;
  final Widget? child;

  const _ModelConsumer({
    required this.builder,
    this.child,
  });

  @override
  State<_ModelConsumer<T>> createState() => _ModelConsumerState<T>();
}

class _ModelConsumerState<T extends Model> extends State<_ModelConsumer<T>> {
  T? _model;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<T>();

    if (!identical(_model, model)) {
      _detachModel(_model);
      _model = model;
      _attachModel(model);
    }
    return widget.builder(context, model, widget.child);
  }

  void _attachModel(T model) {
    if (model is WidgetModel) model.attach(context);
    if (model is ExposedMixin) {
      (model as ExposedMixin).saveSelf(context, owner: this);
    }
    if (model is EventConsumerMixin) {
      (model as EventConsumerMixin).attachTopModelEventOwner(this);
    }
  }

  void _detachModel(T? model) {
    if (model == null) return;
    if (model is WidgetModel) model.detach(context);
    if (model is ExposedMixin) {
      (model as ExposedMixin).removeSelf(owner: this);
    }
    if (model is EventConsumerMixin) {
      (model as EventConsumerMixin).detachTopModelEventOwner(this);
    }
  }

  @override
  void dispose() {
    _detachModel(_model);
    _model = null;
    super.dispose();
  }
}

class LogicWidget<T extends Logic> extends StatefulWidget {
  const LogicWidget({
    super.key,
    required this.create,
    required this.builder,
    this.init,
  });

  final Create<T> create;
  final LogicWidgetBuilder<T> builder;
  final LogicInit<T>? init;

  @override
  State<LogicWidget<T>> createState() => _LogicWidgetState<T>();
}

class _LogicWidgetState<T extends Logic> extends State<LogicWidget<T>> {
  late final T _logic;

  @override
  void initState() {
    super.initState();
    _logic = widget.create(context);
  }

  @override
  Widget build(BuildContext context) {
    return MoProvider<T>.value(
      value: _logic,
      child: InitialBuilder(
        builder: (context) {
          final logic = context.read<T>();
          return widget.builder(context, logic);
        },
        initial: (context, _) {
          final logic = context.read<T>();
          if (logic is WidgetLogic) logic.attach(context);
          if (logic is ExposedMixin) {
            final exposed = logic as ExposedMixin;
            if (!exposed.exposed) {
              exposed.saveSelf(context, owner: this);
            }
          }
          widget.init?.call(context, logic);
        },
        reassemble: (context, _) {
          final logic = context.read<T>();
          if (logic is WidgetLogic) logic.reassemble();
        },
      ),
    );
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }
}

@immutable
class MoLcWidget<T extends Model, R extends Logic> extends StatelessWidget {
  final Create<T>? modelCreate;
  final T? modelValue;
  final Create<R> logicCreate;
  final ModelLogicInit<T, R>? init;
  final ModelLogicWidgetBuilder<T, R> builder;
  final Widget? child;

  const MoLcWidget({
    super.key,
    required this.modelCreate,
    required this.logicCreate,
    required this.builder,
    this.child,
    this.init,
  }) : modelValue = null;

  const MoLcWidget.value({
    super.key,
    required this.modelValue,
    required this.logicCreate,
    required this.builder,
    this.child,
    this.init,
  }) : modelCreate = null;

  Widget _logicLayer(BuildContext context, T model, Widget? child) {
    return LogicWidget<R>(
      create: logicCreate,
      init: (context, logic) {
        if (logic is MoLogic) logic.contact(model);
        init?.call(context, model, logic);
      },
      builder: (context, logic) => builder(context, model, logic, child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mv = modelValue;
    if (mv != null) {
      return ModelWidget<T>.value(
        value: mv,
        builder: _logicLayer,
        child: child,
      );
    }
    return ModelWidget<T>(
      create: modelCreate!,
      builder: _logicLayer,
      child: child,
    );
  }
}

/// NO Model class Widget, for simple model
@immutable
class NoMoWidget<T> extends StatelessWidget {
  final T value;

  final ModelWidgetBuilder<ValueModel<T>> builder;

  const NoMoWidget({
    super.key,
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ModelWidget<ValueModel<T>>(
      create: (_) => ValueModel<T>(value: value),
      builder: builder,
    );
  }
}

@immutable
class NoMo2Widget<A, B> extends StatelessWidget {
  final A value;
  final B value2;

  final ModelWidgetBuilder<Value2Model<A, B>> builder;

  const NoMo2Widget({
    super.key,
    required this.value,
    required this.value2,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ModelWidget<Value2Model<A, B>>(
      create: (_) => Value2Model<A, B>(
        value: value,
        value2: value2,
      ),
      builder: builder,
    );
  }
}

@immutable
class NoMo3Widget<A, B, C> extends StatelessWidget {
  final A value;
  final B value2;
  final C value3;

  final ModelWidgetBuilder<Value3Model<A, B, C>> builder;

  const NoMo3Widget({
    super.key,
    required this.value,
    required this.value2,
    required this.value3,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ModelWidget<Value3Model<A, B, C>>(
      create: (_) => Value3Model<A, B, C>(
        value: value,
        value2: value2,
        value3: value3,
      ),
      builder: builder,
    );
  }
}
