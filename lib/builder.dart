import 'package:flutter/material.dart';

import 'type.dart';

class InitialBuilder extends StatefulWidget {
  const InitialBuilder({
    Key key,
    @required this.builder,
    this.initial,
  })  : assert(builder != null),
        super(key: key);

  final WidgetBuilder builder;
  final Init initial;

  @override
  _InitialBuilderState createState() => _InitialBuilderState();
}

class _InitialBuilderState extends State<InitialBuilder> {
  @override
  void initState() {
    super.initState();
    widget.initial?.call(context);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
