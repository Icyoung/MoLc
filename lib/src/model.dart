import 'package:flutter/widgets.dart';

import 'provider.dart';

/// Interface for objects that need cleanup when removed from the widget tree.
abstract class Disposable {
  /// Release resources held by this object.
  void dispose();
}

/// Base class for UI state models.
///
/// [Model] extends [ChangeNotifier] so that widgets can react to state changes.
/// Call [refresh] to update state and notify listeners.
///
/// For models that need access to [BuildContext], extend [WidgetModel] instead.
///
///     class CounterModel extends Model {
///       int count = 0;
///
///       void increment() {
///         refresh(() => count++);
///       }
///     }
abstract class Model extends Disposable with ChangeNotifier {
  bool _disposed = false;

  /// Whether this model has been disposed.
  bool get disposed => _disposed;

  /// Update state and notify listeners to trigger a UI rebuild.
  ///
  /// The type parameter [T] controls which model gets refreshed:
  /// - If `this` is [T], this model notifies its listeners (default behavior).
  /// - If `this` is NOT [T] (only for [WidgetModel]), the call bubbles up to
  ///   the nearest ancestor [T] in the provider tree.
  ///
  /// Pass a [fn] callback to mutate state before the notification.
  ///
  ///     model.refresh(() {
  ///       model.count++;
  ///     });
  ///
  /// Subclasses mixing in [SelectorMixin] can override [shouldRefresh] to
  /// skip notifications when selected values haven't changed.
  void refresh<T extends Model>([VoidCallback? fn]) {
    if (disposed) return;

    if (this is T) {
      fn?.call();
      if (!shouldRefresh()) return;
      notifyListeners();
    }
  }

  /// Return whether a [refresh] call should notify listeners.
  ///
  /// Override this (e.g. via [SelectorMixin]) to implement conditional refresh.
  bool shouldRefresh() => true;

  @mustCallSuper
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A [Model] that holds a reference to the [BuildContext] of its owning widget.
///
/// Use this when your model needs to access context-based services like
/// [Navigator], [Localizations], or other inherited widgets.
///
/// The context is attached when the model is mounted in a [ModelWidget] or
/// [MoLcWidget], and detached when the widget is removed from the tree.
///
/// **Note:** [context] throws if accessed before attachment or after detachment.
/// Use [contextOrNull] for a null-safe alternative.
///
/// The [refresh] method in [WidgetModel] supports bubbling: calling
/// `refresh<AppModel>()` will notify an ancestor [TopModel] instead of
/// this model, enabling child-to-parent state updates.
abstract class WidgetModel extends Model {
  BuildContext? _context;

  /// The build context of the owning widget.
  ///
  /// Throws if the model is not currently attached to a widget.
  /// Use [contextOrNull] for a null-safe check.
  BuildContext get context => _context!;

  /// Null-safe access to the build context. Returns `null` when detached.
  BuildContext? get contextOrNull => _context;

  /// Whether this model is currently attached to a widget tree.
  bool get attached => _context != null;

  /// Attach this model to the given [context].
  ///
  /// Called internally by [ModelWidget] and [MoLcWidget]. Do not call manually.
  void attach(BuildContext context) {
    _context = context;
  }

  /// Detach this model from the given [context].
  ///
  /// Called internally when the owning widget is removed from the tree.
  void detach(BuildContext context) {
    if (identical(_context, context)) {
      _context = null;
    }
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }

  @override
  bool get disposed => super.disposed || _context == null;

  /// Update state and notify listeners.
  ///
  /// When [T] is this model's type, behaves like [Model.refresh] — notifies
  /// this model's listeners.
  ///
  /// When [T] is a different [Model] type, the callback [fn] is executed and
  /// the refresh call bubbles up to the nearest ancestor provider of type [T].
  /// This enables child widgets to trigger parent model updates:
  ///
  ///     // In a child WidgetModel, refresh the parent model:
  ///     model.refresh<AppModel>(() {
  ///       appModel.someField = newValue;
  ///     });
  @override
  void refresh<T extends Model>([VoidCallback? fn]) {
    super.refresh(fn);

    if (disposed) return;

    if (this is! T) {
      fn?.call();
      context.read<T>().refresh<T>();
    }
  }
}

/// A simple [Model] wrapping a single value.
///
/// Used internally by [NoMoWidget] for lightweight state without defining
/// a custom model class.
class ValueModel<T> extends Model {
  T value;

  ValueModel({required this.value});
}

/// A simple [Model] wrapping two values.
///
/// Used internally by [NoMo2Widget].
class Value2Model<A, B> extends Model {
  A value;
  B value2;

  Value2Model({
    required this.value,
    required this.value2,
  });
}

/// A simple [Model] wrapping three values.
///
/// Used internally by [NoMo3Widget].
class Value3Model<A, B, C> extends Model {
  A value;
  B value2;
  C value3;

  Value3Model({
    required this.value,
    required this.value2,
    required this.value3,
  });
}
