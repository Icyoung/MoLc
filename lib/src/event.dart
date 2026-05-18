import 'container.dart';
import 'model.dart';
import 'top.dart';

/// Mixin for [TopModel] that supports event-driven local refresh.
///
/// Mix this into a [TopModel] to allow specific consumers to react to
/// events without triggering a full global rebuild.
///
///     enum AppEvent { userChanged, themeChanged }
///
///     class AppModel extends TopModel with EventModel<AppEvent> {}
///
/// Then call [refreshEvent] to notify all [EventConsumerMixin] instances
/// listening to that event:
///
///     top<AppModel>().refreshEvent(AppEvent.userChanged);
///
/// The event type [T] should have reliable `==` / `hashCode` semantics.
/// Enums and stable value objects are recommended.
mixin EventModel<T> on TopModel {
  /// Notify all [EventConsumerMixin] instances listening to [event].
  void refreshEvent(T event) {
    final listeners = top<CoreContainer>()._getModelListeners(event);
    for (final refresh in [...?listeners?.values]) {
      refresh.call();
    }
  }
}

/// Internal mixin that stores event-to-listener mappings.
///
/// Mixed into [CoreContainer] automatically. Do not use directly.
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

/// Mixin for [Model] that allows it to listen to events from an [EventModel].
///
/// Use this when a local model should refresh only in response to specific
/// global events, avoiding unnecessary rebuilds.
///
///     class ProfileModel extends Model with EventConsumerMixin {
///       void init() {
///         listenTopModelEvent(AppEvent.userChanged);
///       }
///     }
///
/// The listener is automatically registered when the model is mounted in a
/// [ModelWidget], and removed when the widget unmounts.
///
/// ## Custom refresh and conditions
/// You can provide a custom [refresh] callback and a [test] condition:
///
///     listenTopModelEvent(
///       AppEvent.userChanged,
///       test: () => shouldUpdate,
///       refresh: () {
///         reloadLocalData();
///         refresh();
///       },
///     );
mixin EventConsumerMixin on Model {
  static int _nextId = 0;
  final int _id = _nextId++;
  final Set<Object?> _events = {};
  final Set<Object> _eventOwners = {};
  CoreContainer? _eventContainer;

  /// Called internally when the model is attached to a widget.
  void attachTopModelEventOwner(Object owner) {
    _eventOwners.add(owner);
  }

  /// Called internally when the model is detached from a widget.
  /// Removes all event listeners if this was the last owner.
  void detachTopModelEventOwner(Object owner) {
    _eventOwners.remove(owner);
    if (_eventOwners.isEmpty) {
      removeTopModelEventListeners();
    }
  }

  /// Register a listener for the given [event].
  ///
/// When the event is triggered via [EventModel.refreshEvent], the [refresh]
/// callback (defaulting to [Model.refresh]) is called. If [test] is provided
/// and returns `false`, the refresh is skipped.
///
/// The event key uses the object's `==` / `hashCode` for matching — not
/// `toString()`. Use enums or stable value objects.
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

  /// Remove all registered event listeners for this model.
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