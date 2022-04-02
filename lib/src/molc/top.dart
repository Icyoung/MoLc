import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'container.dart';
import 'model.dart';

class TopModel extends Model {
  static bool get isReady => topKey.currentContext != null;
}

T top<T extends TopModel>() => topKey.currentContext!.read<T>();

final coreContainerProvider =
    ChangeNotifierProvider.value(value: CoreContainer());

final topKey = GlobalKey();

class TopProvider extends StatelessWidget {
  final Widget child;
  final List<SingleChildWidget>? providers;

  const TopProvider({
    Key? key,
    required this.child,
    this.providers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [coreContainerProvider, ...providers ?? []],
      child: Builder(
        key: topKey,
        builder: (_) => child,
      ),
    );
  }
}
