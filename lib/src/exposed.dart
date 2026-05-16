import 'package:flutter/widgets.dart';

import 'top.dart';
import 'container.dart';
import 'model.dart';
import 'provider.dart';

mixin ExposedMixin on Disposable {
  bool? _exposed;
  CoreContainer? _container;
  final Set<Object> _exposeOwners = {};

  bool get exposed => _exposed ?? false;

  @protected
  @Deprecated('topLogic no longer affects exposed cleanup.')
  bool get topLogic => false;

  void saveSelf(BuildContext? context, {Object? owner}) {
    final container = context?.read<CoreContainer>() ?? top<CoreContainer>();
    final exposeOwner = owner ?? this;
    if (_exposed == true && identical(_container, container)) {
      _exposeOwners.add(exposeOwner);
      return;
    }

    _removeFromContainer();
    _exposeOwners
      ..clear()
      ..add(exposeOwner);
    final key = runtimeType;
    (container._exposedMap[key] ??= []).add(this);
    _container = container;
    _exposed = true;
  }

  void removeSelf({Object? owner}) {
    if (_exposed != true) return;
    if (owner != null) {
      _exposeOwners.remove(owner);
      if (_exposeOwners.isNotEmpty) return;
    }
    _exposeOwners.clear();
    _removeFromContainer();
    _container = null;
    _exposed = false;
  }

  void _removeFromContainer() {
    final container = _container;
    final key = runtimeType;
    final list = container?._exposedMap[key];
    if (list != null) {
      list.remove(this);
      if (list.isEmpty) {
        container?._exposedMap.remove(key);
      }
    }
  }

  @override
  void dispose() {
    removeSelf();
    super.dispose();
  }
}

mixin ExposedContainerMixin on TopModel {
  final Map<Type, List<ExposedMixin>> _exposedMap = {};

  static T? find<T extends ExposedMixin>({BuildContext? context}) {
    final container = context?.read<CoreContainer>() ?? top<CoreContainer>();
    final list = container._exposedMap[T];
    if (list == null || list.isEmpty) {
      return null;
    }
    return list.last as T;
  }

  static ExposedMixin? findFuzzy(String exposedModelType,
      {BuildContext? context}) {
    final container = context?.read<CoreContainer>() ?? top<CoreContainer>();
    List<ExposedMixin>? list;
    for (final entry in container._exposedMap.entries) {
      if (entry.key.toString() == exposedModelType) {
        list = entry.value;
        break;
      }
    }
    if (list == null || list.isEmpty) {
      return null;
    }
    return list.last; // Return the last added ExposedMixin
  }
}

T? find<T extends ExposedMixin>({BuildContext? context}) {
  return ExposedContainerMixin.find<T>(context: context);
}

ExposedMixin? findFuzzy(String type, {BuildContext? context}) {
  return ExposedContainerMixin.findFuzzy(type, context: context);
}
