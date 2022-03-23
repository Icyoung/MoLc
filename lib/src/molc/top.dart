import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'model.dart';
import 'part.dart';

GlobalKey topKey = GlobalKey();

class TopModel extends Model {
  static bool get isReady => topKey.currentContext != null;

  static T top<T extends TopModel>() => topKey.currentContext!.read<T>();
}

class TopContainer extends StatelessWidget {
  final Widget app;
  final List<SingleChildWidget>? topModels;

  const TopContainer({
    required this.app,
    this.topModels,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: PartModelContainer()),
        ...topModels ?? []
      ],
      child: Consumer<PartModelContainer>(
        key: topKey,
        builder: (context, container, _) => app,

        ///do something for topContainer
      ),
    );
  }
}

/// T is Event Type, can use enum
mixin EventModel<T> on TopModel {
  Map<T, Set<String>> _eventPartModelListeners = Map();

  ///todo register time and auto register
  void registerSelf() {
    TopModel.top<PartModelContainer>().registerEvent(T.toString(), this);
  }

  void _addPartModelListener(PartModel listener, T event) {
    final listeners = _eventPartModelListeners[event] ??= Set();
    listeners.add(listener.runtimeType.toString());
  }

  void _removePartModelListener(PartModel listener, T event) {
    final listeners = _eventPartModelListeners[event];
    listeners?.remove(listener.runtimeType.toString());
  }

  void refreshEvent(T event) {
    final listeners = _eventPartModelListeners[event];
    listeners?.map((e) => findFuzzy(e)).forEach((e) => e?.refresh());
  }
}

mixin EventContainer on TopModel {
  Map<String, EventModel> _eventMap = SplayTreeMap();

  registerEvent<T>(String eventType, EventModel topModel) {
    _eventMap[eventType] = topModel;
  }

  EventModel? getTopModelFromEvent(String eventType) => _eventMap[eventType];
}

mixin EventConsumerForPartModel on PartModel {
  Set events = Set();

  void listenTopModelEvent<T>(T event) {
    events.add(event);
    final topModel =
        context.read<PartModelContainer>().getTopModelFromEvent(T.toString());
    topModel?._addPartModelListener(this, event);
  }

  @override
  void dispose() {
    events.forEach((e) {
      final topModel = context
          .read<PartModelContainer>()
          .getTopModelFromEvent(e.runtimeType.toString());
      topModel?._removePartModelListener(this, e);
    });
    super.dispose();
  }
}
