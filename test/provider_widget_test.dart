import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;

class _PlainValue {
  final int value;

  const _PlainValue(this.value);
}

void main() {
  testWidgets('MoProvider provides plain values and disposes owned values',
      (tester) async {
    var disposeCalls = 0;
    late _PlainValue value;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MoProvider<_PlainValue>(
          create: (_) => value = const _PlainValue(7),
          dispose: (_) => disposeCalls++,
          child: Builder(
            builder: (context) {
              return Text('plain=${context.watch<_PlainValue>().value}');
            },
          ),
        ),
      ),
    );

    expect(find.text('plain=7'), findsOneWidget);
    expect(value.value, 7);
    expect(disposeCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(disposeCalls, 1);
  });

  testWidgets('MoMultiProvider allows later providers to read earlier ones',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MoMultiProvider(
          providers: [
            moProvider<_PlainValue>((_) => const _PlainValue(2)),
            moProvider<String>((context) {
              return 'derived=${context.read<_PlainValue>().value}';
            }),
          ],
          child: Builder(
            builder: (context) => Text(context.read<String>()),
          ),
        ),
      ),
    );

    expect(find.text('derived=2'), findsOneWidget);
  });

  testWidgets('context.watch rebuilds on notifier refresh but read does not',
      (tester) async {
    late ValueModel<int> model;
    var readBuilds = 0;
    var watchBuilds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MoNotifierProvider<ValueModel<int>>(
          create: (_) => model = ValueModel(value: 0),
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  readBuilds++;
                  return Text('read=${context.read<ValueModel<int>>().value}');
                },
              ),
              Builder(
                builder: (context) {
                  watchBuilds++;
                  return Text(
                      'watch=${context.watch<ValueModel<int>>().value}');
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('read=0'), findsOneWidget);
    expect(find.text('watch=0'), findsOneWidget);
    expect(readBuilds, 1);
    expect(watchBuilds, 1);

    model
      ..value = 1
      ..refresh();
    await tester.pump();

    expect(find.text('read=0'), findsOneWidget);
    expect(find.text('watch=1'), findsOneWidget);
    expect(readBuilds, 1);
    expect(watchBuilds, 2);
  });

  testWidgets('read resolves the nearest provider of the same type',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MoNotifierProvider<ValueModel<int>>(
          create: (_) => ValueModel(value: 1),
          child: MoNotifierProvider<ValueModel<int>>(
            create: (_) => ValueModel(value: 2),
            child: Builder(
              builder: (context) {
                final model = context.read<ValueModel<int>>();
                return Text('nearest=${model.value}');
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('nearest=2'), findsOneWidget);
  });

  testWidgets('context.read throws a FlutterError when provider is missing',
      (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          context.read<_PlainValue>();
          return const SizedBox.shrink();
        },
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
        error.toString(), contains('No MoLc provider found for _PlainValue'));
  });

  testWidgets('context.watch throws a FlutterError when provider is missing',
      (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          context.watch<_PlainValue>();
          return const SizedBox.shrink();
        },
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
        error.toString(), contains('No MoLc provider found for _PlainValue'));
  });
}
