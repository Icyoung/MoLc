import 'dart:async';

import 'package:flutter/material.dart';
import 'package:molc/molc.dart';

void main() {
  runApp(
    TopProvider(
      providers: [
        moNotifierProvider<AppConfigModel>((_) => AppConfigModel()),
        moNotifierProvider<DashboardEventModel>((_) => DashboardEventModel()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DashboardPage(),
      ),
    ),
  );
}

enum DashboardEvent { profileReloaded }

class AppConfigModel extends TopModel {
  String environment = 'staging';
  String baseUrl = 'https://staging.api.example.com';

  void toggleEnvironment() {
    refresh(() {
      if (environment == 'staging') {
        environment = 'production';
        baseUrl = 'https://api.example.com';
      } else {
        environment = 'staging';
        baseUrl = 'https://staging.api.example.com';
      }
    });
  }
}

class DashboardEventModel extends TopModel with EventModel<DashboardEvent> {}

class ApiService {
  Future<String> getProfileSummary() async {
    final config = top<AppConfigModel>();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return 'GET ${config.baseUrl}/profile';
  }
}

class UserRepository {
  UserRepository(this._api);

  final ApiService _api;

  Future<String> loadProfileSummary() {
    return _api.getProfileSummary();
  }
}

final userRepository = UserRepository(ApiService());

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<DashboardModel, DashboardLogic>(
      modelCreate: (_) => DashboardModel(),
      logicCreate: (_) => DashboardLogic(userRepository),
      init: (_, model, logic) => logic.init(model),
      builder: (context, model, logic, _) {
        final config = context.watch<AppConfigModel>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('MoLc layered example'),
            actions: [
              TextButton(
                onPressed: config.toggleEnvironment,
                child: Text(
                  config.environment,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('App base URL: ${config.baseUrl}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: logic.reloadProfile,
                    child: const Text('Load through repository'),
                  ),
                  OutlinedButton(
                    onPressed: logic.pingExposedPanel,
                    child: const Text('Ping exposed sibling'),
                  ),
                  OutlinedButton(
                    onPressed: logic.refreshEventConsumers,
                    child: const Text('Notify event consumers'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSummaryCard(model: model),
              const SizedBox(height: 16),
              const _ActivityPanel(),
              const SizedBox(height: 16),
              const _EventConsumerPanel(),
              const SizedBox(height: 16),
              const _MutableCounterPanel(),
              const SizedBox(height: 16),
              const _TemporaryStatePanel(),
            ],
          ),
        );
      },
    );
  }
}

class DashboardModel extends Model {
  bool loading = false;
  String summary = 'No request yet.';
}

class DashboardLogic extends MoLogic<DashboardModel> {
  DashboardLogic(this._repository);

  final UserRepository _repository;

  void init(DashboardModel model) {}

  Future<void> reloadProfile() async {
    refresh(() {
      model.loading = true;
      model.summary = 'Loading...';
    });

    final summary = await _repository.loadProfileSummary();

    refresh(() {
      model.loading = false;
      model.summary = summary;
    });
  }

  void pingExposedPanel() {
    find<_ActivityPanelModel>()?.addEntry('Pinged by DashboardLogic');
  }

  void refreshEventConsumers() {
    top<DashboardEventModel>().refreshEvent(DashboardEvent.profileReloaded);
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.model});

  final DashboardModel model;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repository + top<AppConfigModel>()',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(model.summary),
            if (model.loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  @override
  Widget build(BuildContext context) {
    return ModelWidget<_ActivityPanelModel>(
      create: (_) => _ActivityPanelModel(),
      builder: (_, model, __) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exposed sibling panel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(model.latestEntry),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityPanelModel extends Model with ExposedMixin {
  String latestEntry = 'Waiting for another component to call find<T>().';

  void addEntry(String entry) {
    refresh(() {
      latestEntry = '$entry at ${DateTime.now().toIso8601String()}';
    });
  }
}

class _EventConsumerPanel extends StatelessWidget {
  const _EventConsumerPanel();

  @override
  Widget build(BuildContext context) {
    return MoLcWidget<_EventPanelModel, _EventPanelLogic>(
      modelCreate: (_) => _EventPanelModel(),
      logicCreate: (_) => _EventPanelLogic(),
      init: (_, model, logic) => logic.init(model),
      builder: (_, model, __, ___) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TopModel event consumer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Event refreshes: ${model.refreshCount}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventPanelModel extends Model with EventConsumerMixin {
  int refreshCount = 0;
}

class _EventPanelLogic extends MoLogic<_EventPanelModel> {
  void init(_EventPanelModel model) {
    model.listenTopModelEvent(
      DashboardEvent.profileReloaded,
      refresh: () {
        refresh(() {
          this.model.refreshCount += 1;
        });
      },
    );
  }
}

class _MutableCounterPanel extends StatefulWidget {
  const _MutableCounterPanel();

  @override
  State<_MutableCounterPanel> createState() => _MutableCounterPanelState();
}

class _MutableCounterPanelState extends State<_MutableCounterPanel> {
  final Mutable<int> _localCount = 0.mt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MutableWidget(
          (_) {
            return Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mutable local counter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${_localCount.value}'),
                IconButton(
                  onPressed: () {
                    _localCount.value += 1;
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TemporaryStatePanel extends StatelessWidget {
  const _TemporaryStatePanel();

  @override
  Widget build(BuildContext context) {
    return NoMoWidget<int>(
      value: 0,
      builder: (_, model, __) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'NoMoWidget temporary state',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${model.value}'),
                IconButton(
                  onPressed: () {
                    model.refresh(() {
                      model.value += 1;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
