import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'container.dart';
import 'model.dart';

GlobalKey topKey = GlobalKey();

class TopModel extends Model {
  static bool get isReady => topKey.currentContext != null;

  static T top<T extends TopModel>() => topKey.currentContext!.read<T>();
}

final partModelContainerProvider =
    ChangeNotifierProvider.value(value: CoreContainer());

class TopContainer extends StatelessWidget {
  final Widget app;
  final List<SingleChildWidget>? topModels;

  const TopContainer({
    required this.app,
    this.topModels,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [partModelContainerProvider, ...topModels ?? []],
      child: Builder(
        key: topKey,
        builder: (_) => app,
      ),
    );
  }
}
