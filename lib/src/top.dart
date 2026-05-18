import 'package:flutter/widgets.dart';

import 'container.dart';
import 'model.dart';
import 'provider.dart';

/// A [Model] registered at the app root via [TopProvider].
///
/// [TopModel] instances can be accessed from anywhere in the app using
/// [top()] or [MoReadContext.read()].
///
/// Mix in [EventModel] to support event-driven local refresh:
///
///     class AppModel extends TopModel with EventModel<AppEvent> {}
///
/// Check [isReady] to verify a [TopProvider] is mounted before calling [top()].
class TopModel extends Model {
  /// Whether a [TopProvider] is currently mounted in the widget tree.
  static bool get isReady => _TopProviderState._currentContext != null;
}

/// Retrieve a [TopModel] from the app root.
///
/// This is a convenience function that works from any [BuildContext]-free
/// context (e.g. inside [Logic], [Model] methods, or utility functions).
///
///     final appModel = top<AppModel>();
///
/// To read within a widget, prefer [MoReadContext.read()] or
/// [MoWatchContext.watch()] for type-safe context-based access.
///
/// Throws if no [TopProvider] is mounted. Check [TopModel.isReady] first.
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

/// Debug access to the internal [GlobalKey] of the current [TopProvider].
///
/// @visibleForTesting
GlobalKey? get debugTopKey => _TopProviderState._current?._topKey;

/// The root provider that holds app-level [TopModel] instances.
///
/// [TopProvider] wraps your app and provides:
/// - A [CoreContainer] for [ExposedMixin] and [EventModel] infrastructure.
/// - Any additional providers specified in [providers].
///
/// Only one [TopProvider] can be mounted at a time. Mounting a second one
/// will throw.
///
///     void main() {
///       runApp(
///         TopProvider(
///           providers: [
///             moNotifierProvider<AppModel>((_) => AppModel()),
///           ],
///           child: const MaterialApp(home: HomePage()),
///         ),
///       );
///     }
///
/// In widget tests, tear down the previous tree with
/// `pumpWidget(const SizedBox.shrink())` before mounting a new [TopProvider].
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