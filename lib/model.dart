import 'package:flutter/material.dart';

abstract class Model with ChangeNotifier {
  bool _disposed = false;

  ///easy to update state
  refresh<T extends Model>([ValueChanged<T> fn]) {
    if (_disposed) return;
    fn?.call(this);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

abstract class WidgetModel extends Model {
  BuildContext _context;

  BuildContext get context => _context;

  ///easy to get context
  attach(BuildContext context) {
    _context = context;
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }
}
