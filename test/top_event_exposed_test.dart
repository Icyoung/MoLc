import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;
import 'package:molc/molc.dart' as molc show find;

enum _Event { changed }

class _TopEventModel extends TopModel with EventModel<_Event> {}

class _TopObjectEventModel extends TopModel with EventModel<Object> {}

class _ExposedModel extends Model with ExposedMixin {}

class _ExposedWidgetModel extends WidgetModel with ExposedMixin {
  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

class _EventConsumerModel extends Model with EventConsumerMixin {
  int refreshCalls = 0;

  @override
  void refresh<T extends Model>([VoidCallback? fn]) {
    refreshCalls++;
    super.refresh(fn);
  }
}

class _CollisionEvent {
  const _CollisionEvent();

  @override
  String toString() => 'same-event-name';
}

void main() {
  testWidgets('TopProvider supports rebuilding the same mounted instance',
      (tester) async {
    Widget tree(String label) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          child: Text(label),
        ),
      );
    }

    await tester.pumpWidget(tree('first'));
    expect(find.text('first'), findsOneWidget);

    await tester.pumpWidget(tree('second'));
    expect(find.text('second'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('top throws a FlutterError before TopProvider is mounted',
      (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      () => top<_TopEventModel>(),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('TopProvider exposes top models through top() and context.read',
      (tester) async {
    late _TopEventModel topModel;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          providers: [
            moNotifierProvider<_TopEventModel>(
                (_) => topModel = _TopEventModel()),
          ],
          child: Builder(
            builder: (context) {
              final byContext = context.read<_TopEventModel>();
              final byTop = top<_TopEventModel>();
              return Text('same=${identical(byContext, byTop)}');
            },
          ),
        ),
      ),
    );

    expect(find.text('same=true'), findsOneWidget);
    expect(identical(top<_TopEventModel>(), topModel), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ExposedMixin registers the latest exposed model',
      (tester) async {
    late _ExposedModel model;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          child: ModelWidget<_ExposedModel>(
            create: (_) => model = _ExposedModel(),
            builder: (_, __, ___) => const Text('ready'),
          ),
        ),
      ),
    );

    expect(find.text('ready'), findsOneWidget);
    expect(identical(molc.find<_ExposedModel>(), model), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ModelWidget.value detaches external exposed model on unmount',
      (tester) async {
    final model = _ExposedWidgetModel();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          child: ModelWidget<_ExposedWidgetModel>.value(
            value: model,
            builder: (_, model, __) => Text('attached=${model.attached}'),
          ),
        ),
      ),
    );

    expect(find.text('attached=true'), findsOneWidget);
    expect(identical(molc.find<_ExposedWidgetModel>(), model), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(model.attached, isFalse);
    expect(model.exposed, isFalse);
    expect(model.disposeCalls, 0);
  });

  testWidgets(
      'ExposedMixin keeps external model exposed until all owners unmount',
      (tester) async {
    final model = _ExposedWidgetModel();

    Widget tree({required bool first, required bool second}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          child: Column(
            children: [
              if (first)
                ModelWidget<_ExposedWidgetModel>.value(
                  key: const ValueKey('first-owner'),
                  value: model,
                  builder: (_, __, ___) => const Text('first'),
                ),
              if (second)
                ModelWidget<_ExposedWidgetModel>.value(
                  key: const ValueKey('second-owner'),
                  value: model,
                  builder: (_, __, ___) => const Text('second'),
                ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(tree(first: true, second: true));
    expect(identical(molc.find<_ExposedWidgetModel>(), model), isTrue);
    expect(model.attached, isTrue);

    await tester.pumpWidget(tree(first: false, second: true));
    expect(identical(molc.find<_ExposedWidgetModel>(), model), isTrue);
    expect(model.attached, isTrue);

    await tester.pumpWidget(tree(first: false, second: false));
    expect(molc.find<_ExposedWidgetModel>(), isNull);
    expect(model.attached, isFalse);
    expect(model.disposeCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('EventModel refreshes registered consumer models',
      (tester) async {
    late _TopEventModel topModel;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          providers: [
            moNotifierProvider<_TopEventModel>(
                (_) => topModel = _TopEventModel()),
          ],
          child: ModelWidget<_EventConsumerModel>(
            create: (_) => _EventConsumerModel(),
            builder: (_, model, __) {
              model.listenTopModelEvent(_Event.changed);
              return Text('refreshes=${model.refreshCalls}');
            },
          ),
        ),
      ),
    );

    expect(find.text('refreshes=0'), findsOneWidget);

    topModel.refreshEvent(_Event.changed);
    await tester.pump();

    expect(find.text('refreshes=1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ModelWidget.value detaches external event consumer on unmount',
      (tester) async {
    late _TopEventModel topModel;
    final consumerModel = _EventConsumerModel();

    Widget tree({required bool showConsumer}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          providers: [
            moNotifierProvider<_TopEventModel>(
                (_) => topModel = _TopEventModel()),
          ],
          child: showConsumer
              ? ModelWidget<_EventConsumerModel>.value(
                  value: consumerModel,
                  builder: (_, model, __) {
                    model.listenTopModelEvent(_Event.changed);
                    return Text('external-refreshes=${model.refreshCalls}');
                  },
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    await tester.pumpWidget(tree(showConsumer: true));

    topModel.refreshEvent(_Event.changed);
    await tester.pump();
    expect(find.text('external-refreshes=1'), findsOneWidget);

    await tester.pumpWidget(tree(showConsumer: false));

    topModel.refreshEvent(_Event.changed);
    await tester.pump();
    expect(consumerModel.refreshCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('EventModel keeps events with identical toString values separate',
      (tester) async {
    late _TopObjectEventModel topModel;
    final listenedEvent = _CollisionEvent();
    final otherEvent = _CollisionEvent();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: TopProvider(
          providers: [
            moNotifierProvider<_TopObjectEventModel>(
                (_) => topModel = _TopObjectEventModel()),
          ],
          child: ModelWidget<_EventConsumerModel>(
            create: (_) => _EventConsumerModel(),
            builder: (_, model, __) {
              model.listenTopModelEvent<Object>(listenedEvent);
              return Text('object-refreshes=${model.refreshCalls}');
            },
          ),
        ),
      ),
    );

    topModel.refreshEvent(otherEvent);
    await tester.pump();
    expect(find.text('object-refreshes=0'), findsOneWidget);

    topModel.refreshEvent(listenedEvent);
    await tester.pump();
    expect(find.text('object-refreshes=1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
