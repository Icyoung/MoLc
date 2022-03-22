import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'model.dart';

GlobalKey topKey = GlobalKey();

class TopModel extends Model {
  static bool get isReady => topKey.currentContext != null;

  static T top<T extends TopModel>() => topKey.currentContext!.read<T>();
}

class TopContainer extends StatelessWidget {
  final Widget app;
  final List<SingleChildWidget>? topModels;

  const TopContainer({
    required this.app,
    this.topModels,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: PartModelContainer()),
        ...topModels ?? []
      ],
      child: Consumer<PartModelContainer>(
        key: topKey,
        builder: (context, container, _) => app,

        ///do something for topContainer
      ),
    );
  }
}

mixin PartModel on WidgetModel {
  void saveSelf(BuildContext? context) {
    (context?.read<PartModelContainer>() ?? TopModel.top<PartModelContainer>())
        ._partModelMap[runtimeType.toString()] = this;
  }

  @override
  void dispose() {
    context
        .read<PartModelContainer>()
        ._partModelMap
        .remove(runtimeType.toString());
    super.dispose();
  }
}

class PartModelContainer extends TopModel {
  Map<String, PartModel> _partModelMap = Map();

  static T find<T extends PartModel>({BuildContext? context}) {
    final container = context != null
        ? context.read<PartModelContainer>()
        : TopModel.top<PartModelContainer>();
    return container._partModelMap[T.toString()] as T;
  }
}

extension FindChildModel on Model {
  T find<T extends PartModel>({BuildContext? context}) {
    return PartModelContainer.find<T>(context: context);
  }
}
