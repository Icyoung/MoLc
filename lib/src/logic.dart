import 'package:flutter/widgets.dart';

import 'model.dart';

abstract class Logic extends Disposable {
  void dispose() {}
}

abstract class WidgetLogic extends Logic {
  BuildContext? _context;

  BuildContext get context => _context!;

  BuildContext? get contextOrNull => _context;

  ///easy to get context
  void attach(BuildContext context) {
    _context = context;
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }

  bool get disposed =>
      _context == null ||
      (context as Element).toStringShort().endsWith('(DEFUNCT)');
}

abstract class MoLogic<T extends Model> extends WidgetLogic {
  T? _model;

  T get model => _model!;

  ///easy to get context
  void contact(T model) {
    _model = model;
  }

  ///easy to update state
  refresh([VoidCallback? fn]) => model.refresh(fn);

  @override
  void dispose() {
    _model = null;
    super.dispose();
  }
}
