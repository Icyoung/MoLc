import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'logic.dart';
import 'top.dart';
import 'container.dart';
import 'model.dart';

mixin ExposedMixin on Disposable {
  bool? _exposed;
  bool get exposed => _exposed ?? false;

  @protected
  bool get topLogic => false; // once topLogic exposed will not dispose

  void saveSelf(BuildContext? context) {
    (context?.read<CoreContainer>() ?? top<CoreContainer>())
        ._exposedMap[runtimeType.toString()] = this;
    _exposed = true;
  }

  void removeSelf() {
    top<CoreContainer>()._exposedMap.remove(runtimeType.toString());
    _exposed = false;
  }

  @override
  void dispose() {
    if (!(this is Logic && topLogic)) {
      removeSelf();
    }
    super.dispose();
  }
}

mixin ExposedContainerMixin on TopModel {
  Map<String, ExposedMixin> _exposedMap = SplayTreeMap();

  static T? find<T extends ExposedMixin>({BuildContext? context}) {
    return findFuzzy(T.toString(), context: context) as T?;
  }

  static ExposedMixin? findFuzzy(String exposedModelType,
      {BuildContext? context}) {
    final container =
        context != null ? context.read<CoreContainer>() : top<CoreContainer>();
    if (!container._exposedMap.containsKey(exposedModelType)) {
      return null;
    }
    return container._exposedMap[exposedModelType];
  }
}

T? find<T extends ExposedMixin>({BuildContext? context}) {
  return ExposedContainerMixin.find<T>(context: context);
}

ExposedMixin? findFuzzy(String type, {BuildContext? context}) {
  return ExposedContainerMixin.findFuzzy(type, context: context);
}
