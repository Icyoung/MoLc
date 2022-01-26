import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model.dart';

abstract class Logic {
  void dispose() {}

  ///easy to read the model above this context node
  T model<T extends Model>(BuildContext context) => context.read<T>();

  ///easy to update state
  refresh<T extends Model>(BuildContext context, [VoidCallback? fn]) =>
      model<T>(context).refresh<T>(fn);
}
