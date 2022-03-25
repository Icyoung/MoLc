# MoLc

⛩A UI Component base on Provider.

By using MoLc, you can:

* The decoupling between the Business Logic, the UI and the UI State Model.

* The State Sharing of Crossing Page.

* The global Model but partly refresh.

## MoLcWidget Sample

Need some template codes, you can using Live Templates of IDE to gen it.
```
class ExamplePage extends StatelessWidget {
  const ExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<_ExampleModel, _ExampleLogic>(
      modelCreate: (_) => _ExampleModel(),
      logicCreate: (_) => _ExampleLogic(),
      init: (_, model, logic) => logic.init(model),
      builder: (context, model, logic, __) => Container(),
    );
  }
}

class _ExampleModel extends Model {}

class _ExampleLogic extends Logic {
  void init(_ExampleModel model) {}
}
```

## Share you model Step 

Firstly，you need wrap a TopProvider above you app, like this:
```
 TopProvider(
      providers: ...,      /// you can custom your topModels here.
      child: MaterialApp(
        ...
      ),
    ),
```

Then, you mixin the PartModel on the Model you want to share.
```
class Test1Model extends WidgetModel with PartModel {}
```

Now, you can find the PartModel at any where, if it is exist and active.
```
find<Test1Model>()?.refresh();

```

## Partly refresh for global Model

Custom event enum for topModel.
```
enum TestEvent { event1, event2, event3 }
```

Mixin EventModel on your topModel.
```
class TestTopModel extends TopModel with EventModel<TestEvent> {}
```

Mixin EventConsumerForModel on your event listener model.
```
class Test2Model extends Model with EventConsumerForModel {}
```

Now, you can refresh partly you topModel.
```
testTopModel.refreshEvent(TestEvent.event1);
```


