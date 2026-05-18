import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;

class _SelectorCounterModel extends Model with SelectorMixin<int> {
  int count = 0;
  bool ignored = false;

  @override
  int selectWith() => count;
}

void main() {
  testWidgets('ModelWidget.value rebuilds when external model.refresh fires',
      (tester) async {
    final model = ValueModel<int>(value: 0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ModelWidget<ValueModel<int>>.value(
          value: model,
          builder: (_, m, __) => Text('count=${m.value}'),
        ),
      ),
    );
    expect(find.text('count=0'), findsOneWidget);

    model
      ..value = 42
      ..refresh();
    await tester.pump();

    expect(find.text('count=42'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(model.disposed, isFalse);
  });

  testWidgets(
      'ModelWidget(create:) constructs the model and rebuilds on refresh',
      (tester) async {
    late ValueModel<String> created;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ModelWidget<ValueModel<String>>(
          create: (_) {
            created = ValueModel<String>(value: 'hi');
            return created;
          },
          builder: (_, m, __) => Text(m.value),
        ),
      ),
    );
    expect(find.text('hi'), findsOneWidget);

    created
      ..value = 'bye'
      ..refresh();
    await tester.pump();

    expect(find.text('bye'), findsOneWidget);

    // Unmount; ValueModel.dispose must not throw.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('refresh callback runs before SelectorMixin refresh check',
      (tester) async {
    late _SelectorCounterModel model;
    var builds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ModelWidget<_SelectorCounterModel>(
          create: (_) => model = _SelectorCounterModel(),
          builder: (_, m, __) {
            builds++;
            return Text('count=${m.count}');
          },
        ),
      ),
    );

    expect(find.text('count=0'), findsOneWidget);
    expect(builds, 1);

    model.refresh();
    await tester.pump();

    expect(builds, 2);

    model.refresh(() {
      model.ignored = true;
    });
    await tester.pump();

    expect(model.ignored, isTrue);
    expect(builds, 2);

    model.refresh(() {
      model.count = 1;
    });
    await tester.pump();

    expect(find.text('count=1'), findsOneWidget);
    expect(builds, 3);
  });
}
