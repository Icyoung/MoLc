import 'package:flutter/material.dart';
import 'package:molc/molc.dart';

void main() {
  runApp(
    const TopContainer(
      app: MaterialApp(
        home: MainPage(),
      ),
    ),
  );
}

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
                  model.find<_Part1Model>().refresh();
                },
                child: Text('refresh Part1'),
              ),
              Part1(),
              SizedBox(
                height: 100,
              ),
              Part2(),
              SizedBox(
                height: 100,
              ),
              Part3(),
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

class _MainModel extends Model {}

class _MainLogic extends Logic {
  void init(_MainModel model) {}
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

class _Part1Model extends Model with PartModel {
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
    refresh<_MainModel>(context);
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