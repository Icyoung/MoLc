import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;

class _FakeLogic extends Logic {
  int initCalls = 0;
  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

void main() {
  testWidgets('LogicWidget runs init once and disposes on unmount',
      (tester) async {
    late _FakeLogic logic;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LogicWidget<_FakeLogic>(
          create: (_) => logic = _FakeLogic(),
          init: (_, l) => l.initCalls++,
          builder: (_, l) => Text('init=${l.initCalls}'),
        ),
      ),
    );

    expect(find.text('init=1'), findsOneWidget);
    expect(logic.initCalls, 1);
    expect(logic.disposeCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(logic.disposeCalls, 1);
  });
}
