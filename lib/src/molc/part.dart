import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:molc/src/molc/top.dart';
import 'package:provider/provider.dart';

import 'container.dart';
import 'model.dart';

mixin PartModel on WidgetModel {
  void saveSelf(BuildContext? context) {
    (context?.read<CoreContainer>() ?? TopModel.top<CoreContainer>())
        ._partModelMap[runtimeType.toString()] = this;
  }

  @override
  void dispose() {
    context.read<CoreContainer>()._partModelMap.remove(runtimeType.toString());
    super.dispose();
  }
}

mixin PartModelContainerForTopModel on TopModel {
  Map<String, PartModel> _partModelMap = SplayTreeMap();

  static T? find<T extends PartModel>({BuildContext? context}) {
    return findFuzzy(T.toString(), context: context) as T;
  }

  static PartModel? findFuzzy(String partModelType, {BuildContext? context}) {
    final container = context != null
        ? context.read<CoreContainer>()
        : TopModel.top<CoreContainer>();
    if (!container._partModelMap.containsKey(partModelType)) {
      return null;
    }
    return container._partModelMap[partModelType];
  }
}

T? find<T extends PartModel>({BuildContext? context}) {
  return PartModelContainerForTopModel.find<T>(context: context);
}

PartModel? findFuzzy(String type, {BuildContext? context}) {
  return PartModelContainerForTopModel.findFuzzy(type, context: context);
}
