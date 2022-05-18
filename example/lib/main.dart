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
  MainPage({Key? key}) : super(key: key);

  final abc = 100.mt;

  final def = 999.mt;

  final ghi = 100.mt;

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<_MainModel, _MainLogic>(
      modelCreate: (_) => _MainModel(),
      logicCreate: (_) => _MainLogic(),
      init: (_, model, logic) => logic.init(model),
      builder: (_, model, logic, __) {
        debugPrint('build==>$runtimeType');
        return Scaffold(
          appBar: AppBar(),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {
                          model.refresh();
                        },
                        child: const Text('refresh MainModel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context
                              .read<TestEventModel>()
                              .refreshEvent(TestEvent.event4);
                          logic.listen();
                        },
                        child: const Text('refresh event4'),
                      ),
                      TextButton(
                        onPressed: () {
                          find<_Part1Model>()?.refresh();
                        },
                        child: const Text('refresh Part1'),
                      ),
                      const Part1(),
                      const SizedBox(
                        height: 20,
                      ),
                      const Part2(),
                      const SizedBox(
                        height: 20,
                      ),
                      const Part3(),
                      const SizedBox(
                        height: 20,
                      ),
                      const Part4(),
                      const SizedBox(
                        height: 20,
                      ),
                      NoMoWidget<int>(
                        value: 99,
                        builder: (_, model, __) {
                          debugPrint('build==>$runtimeType');
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
                                child: const Text('refresh _NoMo2'),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (_, __) => Column(
                      children: [
                        MutableWidget(
                          (context) => Row(
                            children: [
                              Text(def.value.toString()),
                              TextButton(
                                  onPressed: () {
                                    def.value -= 1;
                                  },
                                  child: const Text('-1')),
                              MutableWidget(
                                (context) => Row(
                                  children: [
                                    Text((ghi.value + abc.value).toString()),
                                    TextButton(
                                        onPressed: () {
                                          ghi.value += 1;
                                        },
                                        child: const Text('+1')),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        MutableWidget(
                          (context) => Row(
                            children: [
                              Text(abc.value.toString()),
                              TextButton(
                                  onPressed: () {
                                    abc.value += 1;
                                  },
                                  child: const Text('+1')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
  const Part1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModelWidget<_Part1Model>(
      create: (_) => _Part1Model(),
      builder: (_, model, __) {
        debugPrint('build==>$runtimeType');
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
              child: const Text('refresh _Part1Model'),
            ),
          ],
        );
      },
    );
  }
}

class _Part1Model extends Model with ExposedMixin {
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
        debugPrint('build==>$runtimeType');
        return Row(
          children: [
            TextButton(
              onPressed: () {
                logic.request(context);
              },
              child: const Text('_Part2Logic.request\nthen refresh _MainModel'),
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
    await Future.delayed(const Duration(seconds: 1));
    context.read<_MainModel>().refresh();
  }
}

class Part3 extends StatelessWidget {
  const Part3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NoMoWidget<int>(
      value: 99,
      builder: (_, model, __) {
        debugPrint('build==>$runtimeType');
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
              child: const Text('refresh _NoMo'),
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
          debugPrint('build==>$runtimeType');

          return Row(
            children: const [
              Text('part4'),
            ],
          );
        });
  }
}

class _Part4Model extends Model with ExposedMixin, EventConsumerMixin {}

class _Part4Logic extends Logic {
  void init(_Part4Model model) {
    model.listenTopModelEvent(TestEvent.event4);
  }
}
