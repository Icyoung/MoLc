import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;

void main() {
  testWidgets('MutableWidget rebuilds subscribed widget when value changes',
      (tester) async {
    final count = Mutable<int>(0);
    var builds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MutableWidget(
          (_) {
            builds++;
            return Text('count=${count.value}');
          },
        ),
      ),
    );

    expect(find.text('count=0'), findsOneWidget);
    expect(builds, 1);

    count.value = 1;
    await tester.pump();

    expect(find.text('count=1'), findsOneWidget);
    expect(builds, 2);

    count.value = 1;
    await tester.pump();

    expect(builds, 2);
  });

  testWidgets('Mutable notifies every widget subscribed to the same value',
      (tester) async {
    final shared = Mutable<int>(0);
    var firstBuilds = 0;
    var secondBuilds = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            MutableWidget(
              (_) {
                firstBuilds++;
                return Text('first=${shared.value}');
              },
            ),
            MutableWidget(
              (_) {
                secondBuilds++;
                return Text('second=${shared.value}');
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text('first=0'), findsOneWidget);
    expect(find.text('second=0'), findsOneWidget);
    expect(firstBuilds, 1);
    expect(secondBuilds, 1);

    shared.value = 7;
    await tester.pump();

    expect(find.text('first=7'), findsOneWidget);
    expect(find.text('second=7'), findsOneWidget);
    expect(firstBuilds, 2);
    expect(secondBuilds, 2);
  });

  testWidgets('Mutable cleans up unmounted subscribers on the next write',
      (tester) async {
    final count = Mutable<int>(0);

    Widget tree({required bool show}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: show
            ? MutableWidget((_) => Text('count=${count.value}'))
            : const SizedBox.shrink(),
      );
    }

    await tester.pumpWidget(tree(show: true));
    expect(find.text('count=0'), findsOneWidget);

    await tester.pumpWidget(tree(show: false));
    expect(find.text('count=0'), findsNothing);

    count.value = 1;
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(tree(show: true));
    expect(find.text('count=1'), findsOneWidget);
  });

  testWidgets('Mutable extension helpers delegate to the inner value',
      (tester) async {
    final label = 'MoLc'.mt;
    final enabled = true.mt;
    final nullableEnabled = Mutable<bool?>(true);
    final score = Mutable<int?>(4);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MutableWidget(
          (_) {
            return Text(
              '${label.value.toLowerCase()} '
              '${enabled.value} '
              '${nullableEnabled.isTrue} '
              '${score * 2}',
            );
          },
        ),
      ),
    );

    expect(find.text('molc true true 8'), findsOneWidget);

    nullableEnabled.value = false;
    score.value = 5;
    await tester.pump();

    expect(find.text('molc true false 10'), findsOneWidget);
  });
}
