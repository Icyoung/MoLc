import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';

abstract class Logic {
  @protected
  void dispose() {}
}

abstract class WidgetLogic<T extends Model> extends Logic {
  BuildContext? _context;

  BuildContext get context => _context!;

  T get model => context.read<T>();

  ///easy to update state
  refresh([VoidCallback? fn]) => model.refresh(fn);

  ///easy to get context
  void attach(BuildContext context) {
    _context = context;
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }
}
