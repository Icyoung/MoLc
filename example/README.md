# MoLc Example

This Flutter app demonstrates the main MoLc APIs as a small layered dashboard:

- `TopProvider` registers app-level models such as `AppConfigModel`.
- `DashboardPage` uses `context.watch<AppConfigModel>()` when UI should rebuild.
- `ApiService` is an external singleton-style service that reads
  `top<AppConfigModel>()` for the current `baseUrl`.
- `DashboardLogic` calls a repository and updates `DashboardModel` through
  `MoLogic`.
- `ActivityPanelModel` mixes in `ExposedMixin`, and sibling logic calls it with
  `find<ActivityPanelModel>()`.
- `DashboardEventModel` plus `EventConsumerMixin` demonstrates event-scoped
  refresh.
- `Mutable<T>` and `MutableWidget` demonstrate local reactive state.
- `NoMoWidget` demonstrates simple temporary value state.

Run it from the repository root with:

```bash
cd example
flutter run
```
