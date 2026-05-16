import 'package:flutter/widgets.dart';

import 'container.dart';
import 'model.dart';
import 'provider.dart';

class TopModel extends Model {
  static bool get isReady => _TopProviderState._currentContext != null;
}

T top<T extends TopModel>() {
  final ctx = _TopProviderState._currentContext;
  if (ctx == null) {
    throw FlutterError.fromParts([
      ErrorSummary('top<$T>() called before a TopProvider was mounted.'),
      ErrorDescription(
        'Wrap your app or test root with TopProvider(...) before calling '
        'top<$T>().',
      ),
    ]);
  }
  return ctx.read<T>();
}

@visibleForTesting
GlobalKey? get debugTopKey => _TopProviderState._current?._topKey;

class TopProvider extends StatefulWidget {
  final Widget child;
  final List<MoProviderBuilder>? providers;

  const TopProvider({
    super.key,
    required this.child,
    this.providers,
  });

  @override
  State<TopProvider> createState() => _TopProviderState();
}

class _TopProviderState extends State<TopProvider> {
  static _TopProviderState? _current;

  static BuildContext? get _currentContext => _current?._topKey.currentContext;

  final GlobalKey _topKey = GlobalKey(debugLabel: 'molc.TopProvider');

  @override
  void initState() {
    super.initState();
    final current = _current;
    if (current != null && current.mounted) {
      throw FlutterError.fromParts([
        ErrorSummary('TopProvider is already mounted.'),
        ErrorDescription(
          'MoLc supports a single TopProvider per app. Nesting or mounting two '
          'TopProviders in parallel would make top<T>() ambiguous.',
        ),
        ErrorHint(
          'In widget tests, tear the previous tree down with '
          'pumpWidget(const SizedBox.shrink()) before mounting a new '
          'TopProvider.',
        ),
      ]);
    }
    _current = this;
  }

  @override
  Widget build(BuildContext context) {
    return MoMultiProvider(
      providers: [
        moNotifierProvider((_) => CoreContainer()),
        ...?widget.providers,
      ],
      child: Builder(
        key: _topKey,
        builder: (_) => widget.child,
      ),
    );
  }

  @override
  void dispose() {
    if (identical(_current, this)) {
      _current = null;
    }
    super.dispose();
  }
}
