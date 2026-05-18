import 'package:flutter/widgets.dart';

import 'model.dart';

/// Base class for business logic.
///
/// [Logic] holds request calls, navigation, event handling, and other
/// business behaviors — separate from UI state which lives in [Model].
///
/// For logic that needs [BuildContext], extend [WidgetLogic].
/// For logic tightly bound to a specific [Model], extend [MoLogic].
///
///     class SubmitLogic extends Logic {
///       void submit() {
///         // perform request, navigate, etc.
///       }
///     }
abstract class Logic extends Disposable {
  @override
  void dispose() {}
}

/// A [Logic] that holds a reference to the [BuildContext] of its owning widget.
///
/// Use this when your logic needs context-based services like [Navigator],
/// [showDialog], or other inherited widgets.
///
/// The context is attached automatically by [LogicWidget] and [MoLcWidget].
/// [context] throws if accessed before attachment; use [contextOrNull] for
/// a null-safe alternative.
abstract class WidgetLogic extends Logic {
  BuildContext? _context;

  /// The build context of the owning widget.
  ///
  /// Throws if the logic is not currently attached.
  /// Use [contextOrNull] for a null-safe check.
  BuildContext get context => _context!;

  /// Null-safe access to the build context. Returns `null` when detached.
  BuildContext? get contextOrNull => _context;

  /// Attach this logic to the given [context].
  ///
  /// Called internally by [LogicWidget] and [MoLcWidget]. Do not call manually.
  void attach(BuildContext context) {
    _context = context;
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }

  /// Whether this logic is currently attached to a widget tree.
  bool get disposed => _context == null;

  /// Called when the app is reassembled (e.g. after hot reload).
  ///
  /// Override to reset transient state that should be refreshed on reload.
  void reassemble() {}
}

/// A [WidgetLogic] tightly bound to a specific [Model] type [T].
///
/// Use this when the logic operates on a single model and the pairing is
/// a natural unit (e.g. a page's model and its logic).
///
/// The model is injected via [contact] when the [MoLcWidget] is created.
/// Use [model] to access it, and [refresh] to trigger UI updates.
///
///     class PageLogic extends MoLogic<PageModel> {
///       void reload() {
///         refresh(() {
///           model.loading = true;
///         });
///       }
///     }
///
/// For reusable logic that operates on models passed as method parameters,
/// prefer plain [Logic] or [WidgetLogic] instead of [MoLogic], to avoid
/// coupling the logic to a specific model structure.
abstract class MoLogic<T extends Model> extends WidgetLogic {
  T? _model;

  /// The bound model.
  ///
  /// Throws if accessed before [contact] is called.
  T get model => _model!;

  /// Bind this logic to the given [model].
  ///
  /// Called internally by [MoLcWidget]. Do not call manually.
  void contact(T model) {
    _model = model;
  }

  /// Trigger a UI rebuild by calling [Model.refresh] on the bound model.
  ///
  /// Pass a [fn] callback to mutate model state before the notification.
  void refresh([VoidCallback? fn]) => model.refresh(fn);

  @override
  void dispose() {
    _model = null;
    super.dispose();
  }
}