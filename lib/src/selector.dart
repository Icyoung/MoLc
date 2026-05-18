import 'model.dart';

/// Mixin that enables conditional refresh based on selected values.
///
/// When [refresh] is called, MoLc compares the current [selectWith] result
/// with the previous one. If they are equal (by `==`), the UI is **not**
/// rebuilt — similar to React's `memo` or Flutter's `ValueListenableBuilder`
/// with a custom equality check.
///
///     class PageModel extends Model with SelectorMixin<(int, String)> {
///       int count = 0;
///       String keyword = '';
///       bool loading = false;
///
///       @override
///       (int, String) selectWith() {
///         return (count, keyword);
///       }
///     }
///
/// In the example above, changes to `loading` alone will **not** trigger a
/// rebuild, because `selectWith` only returns `count` and `keyword`.
///
/// ## Notes
/// - The return value of [selectWith] must have reliable `==` semantics.
///   Dart records, tuples, and immutable value objects work well.
/// - If the selected value changes and then reverts to the original, no
///   rebuild is triggered (same as memo semantics).
/// - The first call to [selectWith] always triggers a refresh.
mixin SelectorMixin<T> on Model {
  T? _oldData;

  /// Return the values that determine whether a rebuild should happen.
  ///
  /// The returned value is compared with the previous result using `==`.
  /// If they are equal, the refresh is skipped.
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