import 'package:flutter/widgets.dart';

import 'type.dart';

/// A widget that provides lifecycle hooks (init, reassemble, dispose)
/// alongside a regular builder.
///
/// Used internally by [LogicWidget] to wire up [Logic] lifecycle methods.
///
/// - [initial] is called once during the widget's initialization phase.
/// - [reassemble] is called after hot reload.
/// - [dispose] is called during the widget's disposal phase.
class InitialBuilder extends StatefulWidget {
  const InitialBuilder({
    super.key,
    required this.builder,
    this.initial,
    this.dispose,
    this.reassemble,
  });

  final WidgetBuilder builder;
  final Init? initial;
  final VoidCallback? dispose;
  final Init? reassemble;

  @override
  InitialBuilderState createState() => InitialBuilderState();
}

/// State for [InitialBuilder].
class InitialBuilderState extends State<InitialBuilder> {
  @override
  void initState() {
    super.initState();
    widget.initial?.call(context, refresh);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

  /// Trigger a rebuild of the builder.
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void reassemble() {
    widget.reassemble?.call(context, refresh);
    super.reassemble();
  }

  @override
  void dispose() {
    widget.dispose?.call();
    super.dispose();
  }
}