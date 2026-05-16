import 'container.dart';
import 'model.dart';
import 'top.dart';

/// T is Event Type, can use enum
mixin EventModel<T> on TopModel {
  void refreshEvent(T event) {
    final listeners = top<CoreContainer>()._getModelListeners(event);
    for (final refresh in [...?listeners?.values]) {
      refresh.call();
    }
  }
}

mixin EventContainerMixin on TopModel {
  final Map<Object?, Map<int, void Function()>> _eventModelMap = {};

  Map<int, void Function()>? _getModelListeners<T>(T event) =>
      _eventModelMap[event];

  void _addModelListener<T>(
      EventConsumerMixin listener, T event, void Function() refresh) {
    final listeners = _eventModelMap[event] ??= {};
    listeners[listener._id] = refresh;
  }

  void _removeModelListener<T>(EventConsumerMixin listener, T event) {
    final listeners = _eventModelMap[event];
    listeners?.remove(listener._id);
  }
}

mixin EventConsumerMixin on Model {
  static int _nextId = 0;
  final int _id = _nextId++;
  final Set<Object?> _events = {};
  final Set<Object> _eventOwners = {};
  CoreContainer? _eventContainer;

  void attachTopModelEventOwner(Object owner) {
    _eventOwners.add(owner);
  }

  void detachTopModelEventOwner(Object owner) {
    _eventOwners.remove(owner);
    if (_eventOwners.isEmpty) {
      removeTopModelEventListeners();
    }
  }

  void listenTopModelEvent<T>(
    T event, {
    void Function()? refresh,
    bool Function()? test,
  }) {
    _events.add(event);
    final eventContainer = top<CoreContainer>();
    _eventContainer = eventContainer;
    eventContainer._addModelListener(this, event, () {
      if (!disposed && (test?.call() ?? true)) (refresh ?? this.refresh)();
    });
  }

  @override
  void dispose() {
    removeTopModelEventListeners();
    super.dispose();
  }

  void removeTopModelEventListeners() {
    final eventContainer = _eventContainer;
    for (final e in _events) {
      eventContainer?._removeModelListener(this, e);
    }
    _events.clear();
    _eventOwners.clear();
    _eventContainer = null;
  }
}
