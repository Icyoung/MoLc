import 'dart:async';

import 'package:flutter/material.dart';
import 'package:molc/molc.dart';

void main() {
  runApp(
    TopProvider(
      providers: topModels,
      child: MaterialApp(
        home: MainPage(),
      ),
    ),
  );
}

final topModels = [
  ChangeNotifierProvider(create: (_) => TestEventModel()),
];

enum TestEvent { event1, event2, event3, event4 }

class TestEventModel extends TopModel with EventModel<TestEvent> {}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<_MainModel, _MainLogic>(
      modelCreate: (_) => _MainModel(),
      logicCreate: (_) => _MainLogic(),
      init: (_, model, logic) => logic.init(model),
      builder: (_, model, logic, __) {
        debugPrint('build==>${this.runtimeType}');
        return Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  model.refresh();
                },
                child: Text('refresh MainModel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<TestEventModel>().refreshEvent(TestEvent.event4);
                  logic.listen();
                },
                child: Text('refresh event4'),
              ),
              TextButton(
                onPressed: () {
                  find<_Part1Model>()?.refresh();
                },
                child: Text('refresh Part1'),
              ),
              Part1(),
              SizedBox(
                height: 20,
              ),
              Part2(),
              SizedBox(
                height: 20,
              ),
              Part3(),
              SizedBox(
                height: 20,
              ),
              Part4(),
              SizedBox(
                height: 20,
              ),
              NoMoWidget<int>(
                value: 99,
                builder: (_, model, __) {
                  debugPrint('build==>${this.runtimeType}');
                  return Row(
                    children: [
                      Text(
                        'nomo2:${model.value}',
                      ),
                      TextButton(
                        onPressed: () {
                          model
                            ..value += 1
                            ..refresh();
                        },
                        child: Text('refresh _NoMo2'),
                      ),
                    ],
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}

class _MainModel extends WidgetModel {}

class _MainLogic extends Logic {
  StreamController? controller;
  StreamSubscription? sub;

  void init(_MainModel model) {
    model.context.read<TestEventModel>();
    controller = StreamController();
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      controller?.add('...');
    });
    listen();
  }

  listen() {
    sub?.cancel();
    sub = controller?.stream.asBroadcastStream().listen((event) {
      debugPrint('$event');
    });
  }
}

class Part1 extends StatelessWidget {
  Part1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelWidget<_Part1Model>(
      create: (_) => _Part1Model(),
      builder: (_, model, __) {
        debugPrint('build==>${this.runtimeType}');
        return Row(
          children: [
            Text(
              'part1:${model.part1Num}',
            ),
            TextButton(
              onPressed: () {
                model.part1Num += 1;
                model.refresh();
              },
              child: Text('refresh _Part1Model'),
            ),
          ],
        );
      },
    );
  }
}

class _Part1Model extends WidgetModel with PartModel {
  int part1Num = 66;
}

class Part2 extends StatelessWidget {
  const Part2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LogicWidget<_Part2Logic>(
      create: (_) => _Part2Logic(),
      init: (_, logic) => logic.init(),
      builder: (context, logic) {
        debugPrint('build==>${this.runtimeType}');
        return Row(
          children: [
            TextButton(
              onPressed: () {
                logic.request(context);
              },
              child: Text('_Part2Logic.request\nthen refresh _MainModel'),
            ),
          ],
        );
      },
    );
  }
}

class _Part2Logic extends Logic {
  void init() {}

  void request(BuildContext context) async {
    await Future.delayed(Duration(seconds: 1));
    context.read<_MainModel>().refresh();
  }
}

class Part3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NoMoWidget<int>(
      value: 99,
      builder: (_, model, __) {
        debugPrint('build==>${this.runtimeType}');
        return Row(
          children: [
            Text(
              'nomo:${model.value}',
            ),
            TextButton(
              onPressed: () {
                model
                  ..value += 1
                  ..refresh();
              },
              child: Text('refresh _NoMo'),
            ),
          ],
        );
      },
    );
  }
}

class Part4 extends StatelessWidget {
  const Part4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<_Part4Model, _Part4Logic>(
        modelCreate: (_) => _Part4Model(),
        logicCreate: (_) => _Part4Logic(),
        init: (_, model, logic) => logic.init(model),
        builder: (_, model, logic, __) {
          debugPrint('build==>${this.runtimeType}');

          return Row(
            children: [
              Text(
                'part4',
              ),
            ],
          );
        });
  }
}

class _Part4Model extends WidgetModel with PartModel, EventConsumerForModel {}

class _Part4Logic extends Logic {
  void init(_Part4Model model) {
    model.listenTopModelEvent(TestEvent.event4);
  }
}
