import 'package:flutter/widgets.dart';

import 'type.dart';

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

class InitialBuilderState extends State<InitialBuilder> {
  @override
  void initState() {
    super.initState();
    widget.initial?.call(context, refresh);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);

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
