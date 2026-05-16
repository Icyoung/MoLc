import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:molc/molc.dart' hide find;

class _FakeModel extends Model {
  int counter = 0;
}

class _FakeLogic extends MoLogic<_FakeModel> {
  int initCalls = 0;
}

class _PlainLogic extends Logic {
  int initCalls = 0;
}

class _PageModel extends WidgetModel {
  int counter = 0;
}

void main() {
  testWidgets(
      'MoLcWidget wires model + logic, contacts MoLogic.model, '
      'and rebuilds on model.refresh', (tester) async {
    late _FakeModel model;
    late _FakeLogic logic;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MoLcWidget<_FakeModel, _FakeLogic>(
          modelCreate: (_) => model = _FakeModel(),
          logicCreate: (_) => logic = _FakeLogic(),
          init: (_, m, l) => l.initCalls++,
          builder: (_, m, l, __) => Text('counter=${m.counter}'),
        ),
      ),
    );

    expect(find.text('counter=0'), findsOneWidget);
    expect(logic.initCalls, 1);
    expect(identical(logic.model, model), isTrue);

    model.counter = 7;
    model.refresh();
    await tester.pump();

    expect(find.text('counter=7'), findsOneWidget);
  });

  testWidgets('MoLcWidget tolerates non-MoLogic Logic (no contact required)',
      (tester) async {
    late _FakeModel model;
    late _PlainLogic logic;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MoLcWidget<_FakeModel, _PlainLogic>(
          modelCreate: (_) => model = _FakeModel(),
          logicCreate: (_) => logic = _PlainLogic(),
          init: (_, m, l) => l.initCalls++,
          builder: (_, m, l, __) => Text('counter=${m.counter}'),
        ),
      ),
    );

    expect(find.text('counter=0'), findsOneWidget);
    expect(logic.initCalls, 1);

    model.counter = 3;
    model.refresh();
    await tester.pump();

    expect(find.text('counter=3'), findsOneWidget);
  });

  testWidgets('WidgetModel still refreshes after deactivate/reactivate cycle',
      (tester) async {
    final pageKey = GlobalKey();
    late _PageModel pageModel;

    Widget tree({required bool show}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: show
            ? KeyedSubtree(
                key: pageKey,
                child: ModelWidget<_PageModel>(
                  create: (_) => pageModel = _PageModel(),
                  builder: (_, m, __) => Text('count=${m.counter}'),
                ),
              )
            : Offstage(
                child: KeyedSubtree(
                  key: pageKey,
                  child: ModelWidget<_PageModel>(
                    create: (_) => pageModel = _PageModel(),
                    builder: (_, m, __) => Text('count=${m.counter}'),
                  ),
                ),
              ),
      );
    }

    await tester.pumpWidget(tree(show: true));
    expect(find.text('count=0'), findsOneWidget);

    // Trigger deactivate/reactivate by toggling Offstage parentage
    // (the same Element gets reparented; mounted briefly flips false).
    await tester.pumpWidget(tree(show: false));
    await tester.pumpWidget(tree(show: true));

    pageModel.counter = 9;
    pageModel.refresh();
    await tester.pump();

    expect(find.text('count=9'), findsOneWidget);
  });
}
