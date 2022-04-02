import 'model.dart';

mixin SelectorMixin<T> on Model {
  T? _oldData;

  T selectWith();

  @override
  bool shouldRefresh() {
    if (_oldData != null) {
      T clone = selectWith();
      bool same = _oldData == clone;
      if (!same) {
        _oldData = clone;
      }
      return !same;
    }
    _oldData = selectWith();
    return super.shouldRefresh();
  }
}
