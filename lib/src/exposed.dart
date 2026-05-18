import 'package:flutter/widgets.dart';

import 'top.dart';
import 'container.dart';
import 'model.dart';
import 'provider.dart';

/// Mixin that registers the current instance in the [CoreContainer] so it can
/// be looked up from anywhere via [find()].
///
/// Use this when you need parent-to-child access, sibling-to-sibling access,
/// or non-widget layers (e.g. [Logic]) calling into an active model/logic.
///
///     class DetailModel extends Model with ExposedMixin {
///       void reload() {}
///     }
///
/// Lookup:
///
///     find<DetailModel>()?.reload();
///
/// ## Rules
/// - `find<T>()` returns the last-registered instance of type `T`.
/// - The instance is automatically removed when the owning widget unmounts.
/// - External objects (`.value` constructors) are **not** disposed, but are
///   still removed from the active registry on unmount.
/// - For multiple owners sharing the same external instance, the instance
///   remains registered until **all** owners unmount.
mixin ExposedMixin on Disposable {
  bool? _exposed;
  CoreContainer? _container;
  final Set<Object> _exposeOwners = {};

  /// Whether this instance is currently registered in the container.
  bool get exposed => _exposed ?? false;

  @protected
  @Deprecated('topLogic no longer affects exposed cleanup.')
  bool get topLogic => false;

  /// Register this instance in the [CoreContainer] under its runtime type.
  ///
  /// If already registered in the same container, [owner] is added to the
  /// internal owner set. If the container changes, the old registration is
  /// cleared first.
  ///
  /// Called internally by [ModelWidget] and [LogicWidget]. Do not call manually.
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

  /// Remove this instance from the container if [owner] is the last owner.
  ///
  /// When [owner] is `null`, removes unconditionally (used during [dispose]).
  ///
  /// Called internally by [ModelWidget] and [LogicWidget]. Do not call manually.
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

/// Internal mixin that provides a registry for [ExposedMixin] instances.
///
/// Mixed into [CoreContainer] automatically. Do not use directly.
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

  /// Fuzzy lookup by type name string.
  ///
  /// Prefer the type-safe [find<T>()] function. This is kept for legacy code
  /// that resolves exposed instances dynamically.
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
    return list.last;
  }
}

/// Find the last-registered [ExposedMixin] of type [T].
///
/// Returns `null` if no instance of [T] is currently active.
///
///     find<DetailModel>()?.reload();
///
/// If a [context] is provided, it is used to look up the [CoreContainer]
/// via [MoReadContext.read]. Otherwise, the global [top()] function is used.
T? find<T extends ExposedMixin>({BuildContext? context}) {
  return ExposedContainerMixin.find<T>(context: context);
}

/// Fuzzy lookup for an exposed instance by its type name string.
///
/// Prefer [find<T>()] for type-safe access.
ExposedMixin? findFuzzy(String type, {BuildContext? context}) {
  return ExposedContainerMixin.findFuzzy(type, context: context);
}