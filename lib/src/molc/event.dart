import 'dart:collection';

import 'package:molc/molc.dart';
import 'package:molc/src/molc/container.dart';

/// T is Event Type, can use enum
mixin EventModel<T> on TopModel {
  void refreshEvent(T event) {
    final listeners =
        TopModel.top<CoreContainer>()._getPartModelListeners(event);
    listeners?.map((e) => findFuzzy(e)).forEach((e) => e?.refresh());
  }
}

mixin EventContainerForTopModel on TopModel {
  Map<String, Set<String>> _eventPartModelMap = SplayTreeMap();

  Set<String>? _getPartModelListeners<T>(T event) =>
      _eventPartModelMap[event.toString()];

  void _addPartModelListener<T>(PartModel listener, T event) {
    final listeners = _eventPartModelMap[event.toString()] ??= Set();
    listeners.add(listener.runtimeType.toString());
  }

  void _removePartModelListener<T>(PartModel listener, T event) {
    final listeners = _eventPartModelMap[event.toString()];
    listeners?.remove(listener.runtimeType.toString());
  }
}

mixin EventConsumerForPartModel on PartModel {
  Set events = Set();

  void listenTopModelEvent<T>(T event) {
    events.add(event);
    final eventContainer = context.read<CoreContainer>();
    eventContainer._addPartModelListener(this, event);
  }

  @override
  void dispose() {
    events.forEach((e) {
      final eventContainer = context.read<CoreContainer>();
      eventContainer._removePartModelListener(this, e);
    });
    super.dispose();
  }
}
