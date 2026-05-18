import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'type.dart';

const int _mutableSize = 3;

/// A reactive value that triggers rebuilds in surrounding [MutableWidget]s.
///
/// Reading [value] inside a [MutableWidget] builder automatically registers
/// that widget as a subscriber. Writing to [value] notifies all subscribers
/// to rebuild — similar to GetX's `Rx` types or Jetpack Compose's
/// `mutableStateOf`.
///
///     final count = 0.mt;
///
///     MutableWidget((context) {
///       return Row(
///         children: [
///           Text('${count.value}'),
///           TextButton(
///             onPressed: () => count.value += 1,
///             child: const Text('+1'),
///           ),
///         ],
///       );
///     });
///
/// ## How it works
/// [Mutable] relies on Flutter's single-threaded event loop. The [value]
/// getter captures the current [MutableWidget] via a static delegate set
/// during the widget's build phase. This enables automatic subscription
/// and unsubscription without explicit API calls.
///
/// This static build-phase delegate is intentional. It is the mechanism that
/// gives [Mutable] GetX-like automatic dependency tracking while Flutter runs
/// widget builds synchronously on one isolate. Do not replace it with an
/// explicit subscription API unless the automatic tracking model is changing.
///
/// ## Rules
/// - [value] must be read synchronously inside a [MutableWidget] builder.
/// - [value] can be written from event callbacks, async callbacks, etc.
/// - Do not read [value] (or call [toString]) outside a [MutableWidget]
///   context — there is no widget to bind the refresh to.
/// - [MutableWidget] supports nesting and multiple widgets subscribing to
///   the same [Mutable].
class Mutable<T> extends RefreshDelegate {
  late final Queue<T> _data;

  /// Read the current value and register the surrounding [MutableWidget]
  /// as a subscriber.
  ///
  /// Must be called synchronously inside a [MutableWidget] builder.
  T get value {
    final entry = RefreshDelegate._delegate!;
    _refreshMap ??= <Object, RefreshCallback>{};
    _refreshMap![entry.key] = entry.value;
    return _data.last;
  }

  /// Set a new value and notify all subscribers.
  ///
  /// If the new value equals the current one (by `==`), no notification is sent.
  /// Unmounted widgets are automatically removed from the subscriber list.
  set value(T value) {
    if (value == _data.last) return;
    if (_data.length == _mutableSize) {
      _data.removeFirst();
    }
    _data.add(value);

    final removeSet = <Object>{};
    _refreshMap?.forEach((k, v) {
      if (!v.call()) removeSet.add(k);
    });
    for (final e in removeSet) {
      _refreshMap?.remove(e);
    }
  }

  /// Create a [Mutable] with the given initial [value].
  Mutable(T value) : _data = Queue.from([value]);

  @override
  String toString() {
    return value.toString();
  }
}

/// A widget that enables [Mutable] values to trigger rebuilds.
///
/// During build, it sets a static delegate so that any [Mutable.value]
/// read inside [builder] can register this widget as a subscriber.
///
/// When a subscribed [Mutable] is written to, this widget triggers a rebuild.
///
///     MutableWidget((context) {
///       return Text('${myMutable.value}');
///     });
class MutableWidget extends StatefulWidget {
  /// The builder function. Read [Mutable.value] here to subscribe.
  final WidgetBuilder builder;

  const MutableWidget(this.builder, {super.key});

  @override
  State<StatefulWidget> createState() => _MutableState();
}

class _MutableState extends State<MutableWidget> {
  /// Called by [Mutable] when its value changes. Returns `true` if still mounted.
  bool refresh() {
    if (mounted) {
      setState(() {});
    }
    return mounted;
  }

  @override
  Widget build(BuildContext context) {
    RefreshDelegate._delegate = MapEntry(this, refresh);
    return widget.builder(context);
  }
}

/// Base class for [Mutable] that holds the static build-phase delegate.
///
/// The static [_delegate] is set by [MutableWidget] during its build method
/// and is read by [Mutable.value] to register the current widget as a subscriber.
/// This works safely because Flutter's build phase is synchronous and single-threaded.
/// It is a deliberate part of [Mutable]'s subscription model, not leftover
/// global state.
abstract class RefreshDelegate {
  static MapEntry<Object, RefreshCallback>? _delegate;

  Map<Object, RefreshCallback>? _refreshMap;
}

/// Convert a [String] to a [Mutable<String>].
extension MutableStringExt on String {
  Mutable<String> get mt => Mutable(this);
}

/// Convert a [bool] to a [Mutable<bool>].
extension MutableBoolExt on bool {
  Mutable<bool> get mt => Mutable(this);
}

/// Convert an [int] to a [Mutable<int>].
extension MutableIntExt on int {
  Mutable<int> get mt => Mutable(this);
}

/// Convert a [double] to a [Mutable<double>].
extension MutableDoubleExt on double {
  Mutable<double> get mt => Mutable(this);
}

/// Convert a [num] to a [Mutable<num>].
extension MutableNumExt on num {
  Mutable<num> get mt => Mutable(this);
}

/// Convert a [List] to a [Mutable<List<T>>].
extension MutableListExtension<T> on List<T> {
  Mutable<List<T>> get mt => Mutable(this);
}

/// Convert any value to a [Mutable<T>].
extension MutableT<T> on T {
  Mutable<T> get mt => Mutable<T>(this);
}

/// String operations on [Mutable<String?>] that delegate to the inner value.
///
/// Null-safe: returns `null` when the inner value is null (except [operator +]
/// which treats null as an empty string).
extension MutableStringFunExt on Mutable<String?> {
  String operator +(String val) => (value ?? '') + val;

  int? compareTo(String other) => value?.compareTo(other);

  bool? endsWith(String other) => value?.endsWith(other);

  bool? startsWith(Pattern pattern, [int index = 0]) =>
      value?.startsWith(pattern, index);

  int? indexOf(Pattern pattern, [int start = 0]) =>
      value?.indexOf(pattern, start);

  int? lastIndexOf(Pattern pattern, [int? start]) =>
      value?.lastIndexOf(pattern, start);

  bool? get isEmpty => value?.isEmpty;

  bool? get isNotEmpty => value?.isNotEmpty;

  String? substring(int startIndex, [int? endIndex]) =>
      value?.substring(startIndex, endIndex);

  String? trim() => value?.trim();

  String? trimLeft() => value?.trimLeft();

  String? trimRight() => value?.trimRight();

  String? padLeft(int width, [String padding = ' ']) =>
      value?.padLeft(width, padding);

  String? padRight(int width, [String padding = ' ']) =>
      value?.padRight(width, padding);

  bool? contains(Pattern other, [int startIndex = 0]) =>
      value?.contains(other, startIndex);

  String? replaceAll(Pattern from, String replace) =>
      value?.replaceAll(from, replace);

  List<String>? split(Pattern pattern) => value?.split(pattern);

  List<int>? get codeUnits => value?.codeUnits;

  Runes? get runes => value?.runes;

  String? toLowerCase() => value?.toLowerCase();

  String? toUpperCase() => value?.toUpperCase();

  Iterable<Match>? allMatches(String string, [int start = 0]) =>
      value?.allMatches(string, start);

  Match? matchAsPrefix(String string, [int start = 0]) =>
      value?.matchAsPrefix(string, start);
}

/// Boolean operations on [Mutable<bool?>].
extension MutableBoolFunExt on Mutable<bool?> {
  /// Returns `true` if the value is `true`, `false` otherwise.
  bool get isTrue => value ?? false;

  /// Returns `true` if the value is `false` or `null`.
  bool get isFalse => !isTrue;

  bool operator &(bool other) => other && (value ?? false);

  bool operator |(bool other) => other || (value ?? false);

  bool operator ^(bool other) => !other == value;

  /// Toggle the boolean value.
  Mutable<bool?> toggle() {
    if (value != null) {
      value = !value!;
    }
    return this;
  }
}

/// Numeric operations on [Mutable<T?>] where [T] extends [num].
///
/// All operators and methods are null-safe: they return `null` when the
/// inner value is null.
extension MutableNumFunExt<T extends num> on Mutable<T?> {
  num? operator *(num other) => value != null ? value! * other : null;

  num? operator %(num other) => value != null ? value! % other : null;

  double? operator /(num other) => value != null ? value! / other : null;

  int? operator ~/(num other) => value != null ? value! ~/ other : null;

  num? operator -() => value != null ? -value! : null;

  num? remainder(num other) => value?.remainder(other);

  bool? operator <(num other) => value != null ? value! < other : null;

  bool? operator <=(num other) => value != null ? value! <= other : null;

  bool? operator >(num other) => value != null ? value! > other : null;

  bool? operator >=(num other) => value != null ? value! >= other : null;

  bool? get isNaN => value?.isNaN;

  bool? get isNegative => value?.isNegative;

  bool? get isInfinite => value?.isInfinite;

  bool? get isFinite => value?.isFinite;

  num? abs() => value?.abs();

  num? get sign => value?.sign;

  int? round() => value?.round();

  int? floor() => value?.floor();

  int? ceil() => value?.ceil();

  int? truncate() => value?.truncate();

  double? roundToDouble() => value?.roundToDouble();

  double? floorToDouble() => value?.floorToDouble();

  double? ceilToDouble() => value?.ceilToDouble();

  double? truncateToDouble() => value?.truncateToDouble();

  num? clamp(num lowerLimit, num upperLimit) =>
      value?.clamp(lowerLimit, upperLimit);

  int? toInt() => value?.toInt();

  double? toDouble() => value?.toDouble();

  String? toStringAsFixed(int fractionDigits) =>
      value?.toStringAsFixed(fractionDigits);

  String? toStringAsExponential([int? fractionDigits]) =>
      value?.toStringAsExponential(fractionDigits);

  String? toStringAsPrecision(int precision) =>
      value?.toStringAsPrecision(precision);
}
