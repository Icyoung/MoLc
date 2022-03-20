import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

import 'logic.dart';

abstract class Model with ChangeNotifier {
  bool _disposed = false;

  bool get disposed => _disposed;

  ///easy to update state
  void refresh<T extends Model>([VoidCallback? fn]) {
    if (disposed) return;

    /// refresh this model
    if (this is T) {
      debugPrint('refresh==>${this.runtimeType}');
      fn?.call();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

abstract class WidgetModel extends Model {
  BuildContext? _context;

  BuildContext get context => _context!;

  BuildContext? get contextOrNull => _context;

  bool get attached => _context != null;

  ///easy to get context
  void attach(BuildContext context) {
    _context = context;
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }

  @override
  bool get disposed =>
      _context == null ||
      (context as Element).toStringShort().endsWith('(DEFUNCT)');

  @override
  void refresh<T extends Model>([VoidCallback? fn]) {
    super.refresh(fn);

    if (disposed) return;

    ///refresh higher level model
    if (!(this is T)) {
      fn?.call();
      context.read<T>().refresh();
    }
  }
}

abstract class PageModel<T extends Logic> extends WidgetModel {
  T? _logic;

  T get logic => _logic!;

  ///easy to get logic
  void contact(Logic logic) {
    if (logic is T) {
      _logic = logic;
    }
  }
}

/// for simple model impl
class ValueModel<T> extends Model {
  T value;

  ValueModel({required this.value});
}

class Value2Model<A, B> extends Model {
  A value;
  B value2;

  Value2Model({
    required this.value,
    required this.value2,
  });
}

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
