import 'package:flutter/widgets.dart';

import 'type.dart';

class InitialBuilder extends StatefulWidget {
  const InitialBuilder({
    Key? key,
    required this.builder,
    this.initial,
    this.dispose,
  }) : super(key: key);

  final WidgetBuilder builder;
  final Init? initial;
  final VoidCallback? dispose;

  @override
  _InitialBuilderState createState() => _InitialBuilderState();
}

class _InitialBuilderState extends State<InitialBuilder> {
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
  void dispose() {
    widget.dispose?.call();
    super.dispose();
  }
}
