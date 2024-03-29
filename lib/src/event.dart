import 'dart:collection';

import 'container.dart';
import 'model.dart';
import 'top.dart';

/// T is Event Type, can use enum
mixin EventModel<T> on TopModel {
  void refreshEvent(T event) {
    final listeners = top<CoreContainer>()._getModelListeners(event);
    listeners?.forEach((_, refresh) {
      refresh.call();
    });
  }
}

mixin EventContainerMixin on TopModel {
  Map<String, Map<String, void Function()>> _eventModelMap = SplayTreeMap();

  Map<String, void Function()>? _getModelListeners<T>(T event) =>
      _eventModelMap[event.toString()];

  void _addModelListener<T>(Model listener, T event, void refresh()) {
    final listeners = _eventModelMap[event.toString()] ??= SplayTreeMap();
    listeners[listener.runtimeType.toString()] = refresh;
  }

  void _removeModelListener<T>(Model listener, T event) {
    final listeners = _eventModelMap[event.toString()];
    listeners?.remove(listener.runtimeType.toString());
  }
}

mixin EventConsumerMixin on Model {
  Set events = Set();

  void listenTopModelEvent<T>(T event, {void refresh()?, bool test()?}) {
    events.add(event);
    final eventContainer = top<CoreContainer>();
    eventContainer._addModelListener(this, event, () {
      if (!disposed && (test?.call() ?? true)) (refresh ?? this.refresh)();
    });
  }

  @override
  void dispose() {
    events.forEach((e) {
      final eventContainer = top<CoreContainer>();
      eventContainer._removeModelListener(this, e);
    });
    super.dispose();
  }
}
