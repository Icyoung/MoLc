import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:molc/src/molc/top.dart';
import 'package:provider/provider.dart';

import 'model.dart';

mixin PartModel on WidgetModel {
  void saveSelf(BuildContext? context) {
    (context?.read<PartModelContainer>() ?? TopModel.top<PartModelContainer>())
        ._partModelMap[runtimeType.toString()] = this;
  }

  @override
  void dispose() {
    context
        .read<PartModelContainer>()
        ._partModelMap
        .remove(runtimeType.toString());
    super.dispose();
  }
}

class PartModelContainer extends TopModel with EventContainer {
  Map<String, PartModel> _partModelMap = SplayTreeMap();

  static T? find<T extends PartModel>({BuildContext? context}) {
    return findFuzzy(T.toString(), context: context) as T;
  }

  static PartModel? findFuzzy(String partModelType, {BuildContext? context}) {
    final container = context != null
        ? context.read<PartModelContainer>()
        : TopModel.top<PartModelContainer>();
    if (!container._partModelMap.containsKey(partModelType)) {
      return null;
    }
    return container._partModelMap[partModelType];
  }
}

extension FindChildModel on Model {
  T? find<T extends PartModel>({BuildContext? context}) {
    return PartModelContainer.find<T>(context: context);
  }

  PartModel? findFuzzy(String type, {BuildContext? context}) {
    return PartModelContainer.findFuzzy(type, context: context);
  }
}
