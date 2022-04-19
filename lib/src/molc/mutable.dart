import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'type.dart';

const int _MUTABLE_SIZE = 3;

class Mutable<T> extends RefreshDelegate {
  late Queue<T> _data;

  T get value {
    final entry = RefreshDelegate._delegate!;
    _refreshMap ??= SplayTreeMap();
    _refreshMap![entry.key] = entry.value;
    return _data.last;
  }

  set value(T value) {
    if (_data.length == _MUTABLE_SIZE) {
      _data.removeFirst();
    }
    _data.add(value);

    final removeSet = Set();
    _refreshMap?.forEach((k, v) {
      if (!v.call()) removeSet.add(k);
    });
    removeSet.forEach((e) {
      _refreshMap?.remove(e);
    });
  }

  Mutable(T value) : _data = Queue.from([value]);

  @override
  String toString() {
    return value.toString();
  }
}

class MutableWidget extends StatefulWidget {
  final WidgetBuilder builder;

  const MutableWidget(this.builder);

  @override
  State<StatefulWidget> createState() => _MutableState();
}

class _MutableState extends State<MutableWidget> {
  bool refresh() {
    if (mounted) {
      setState(() {});
    }
    return mounted;
  }

  @override
  Widget build(BuildContext context) {
    RefreshDelegate._delegate = MapEntry(hashCode, refresh);
    return widget.builder(context);
  }
}

abstract class RefreshDelegate {
  static MapEntry<int, RefreshCallback>? _delegate;

  Map<int, RefreshCallback>? _refreshMap;
}

extension MutableStringExt on String {
  Mutable<String> get mt => Mutable(this);
}

extension MutableBoolExt on bool {
  Mutable<bool> get mt => Mutable(this);
}

extension MutableIntExt on int {
  Mutable<int> get mt => Mutable(this);
}

extension MutableDoubleExt on double {
  Mutable<double> get mt => Mutable(this);
}

extension MutableNumExt on num {
  Mutable<num> get mt => Mutable(this);
}

extension MutableListExtension<T> on List<T> {
  Mutable<List<T>> get mt => Mutable(this);
}

extension MutableT<T> on T {
  Mutable<T> get mt => Mutable<T>(this);
}

extension MutableStringFunExt on Mutable<String?> {
  String operator +(String val) => (value ?? '') + val;

  int? compareTo(String other) {
    return value?.compareTo(other);
  }

  bool? endsWith(String other) {
    return value?.endsWith(other);
  }

  bool? startsWith(Pattern pattern, [int index = 0]) {
    return value?.startsWith(pattern, index);
  }

  int? indexOf(Pattern pattern, [int start = 0]) {
    return value?.indexOf(pattern, start);
  }

  int? lastIndexOf(Pattern pattern, [int? start]) {
    return value?.lastIndexOf(pattern, start);
  }

  bool? get isEmpty => value?.isEmpty;

  bool? get isNotEmpty => value?.isNotEmpty;

  String? substring(int startIndex, [int? endIndex]) {
    return value?.substring(startIndex, endIndex);
  }

  String? trim() {
    return value?.trim();
  }

  String? trimLeft() {
    return value?.trimLeft();
  }

  String? trimRight() {
    return value?.trimRight();
  }

  String? padLeft(int width, [String padding = ' ']) {
    return value?.padLeft(width, padding);
  }

  String? padRight(int width, [String padding = ' ']) {
    return value?.padRight(width, padding);
  }

  bool? contains(Pattern other, [int startIndex = 0]) {
    return value?.contains(other, startIndex);
  }

  String? replaceAll(Pattern from, String replace) {
    return value?.replaceAll(from, replace);
  }

  List<String>? split(Pattern pattern) {
    return value?.split(pattern);
  }

  List<int>? get codeUnits => value?.codeUnits;

  Runes? get runes => value?.runes;

  String? toLowerCase() {
    return value?.toLowerCase();
  }

  String? toUpperCase() {
    return value?.toUpperCase();
  }

  Iterable<Match>? allMatches(String string, [int start = 0]) {
    return value?.allMatches(string, start);
  }

  Match? matchAsPrefix(String string, [int start = 0]) {
    return value?.matchAsPrefix(string, start);
  }
}

extension MutableBoolFunExt on Mutable<bool?> {
  bool get isTrue => value ?? false;

  bool get isFalse => !isTrue;

  bool operator &(bool other) => other && (value ?? false);

  bool operator |(bool other) => other || (value ?? false);

  bool operator ^(bool other) => !other == value;

  Mutable<bool?> toggle() {
    if (value != null) {
      value = !value!;
    }
    return this;
  }
}

extension MutableNumFunExt<T extends num> on Mutable<T?> {
  num? operator *(num other) {
    if (value != null) {
      return value! * other;
    }
  }

  num? operator %(num other) {
    if (value != null) {
      return value! % other;
    }
  }

  double? operator /(num other) {
    if (value != null) {
      return value! / other;
    }
  }

  int? operator ~/(num other) {
    if (value != null) {
      return value! ~/ other;
    }
  }

  num? operator -() {
    if (value != null) {
      return -value!;
    }
  }

  num? remainder(num other) => value?.remainder(other);

  bool? operator <(num other) {
    if (value != null) {
      return value! < other;
    }
  }

  bool? operator <=(num other) {
    if (value != null) {
      return value! <= other;
    }
  }

  bool? operator >(num other) {
    if (value != null) {
      return value! > other;
    }
  }

  bool? operator >=(num other) {
    if (value != null) {
      return value! >= other;
    }
  }

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
