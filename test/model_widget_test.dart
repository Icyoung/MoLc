import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;

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
}
