# MoLc Example

This Flutter app demonstrates the main MoLc APIs in one small screen:

- `TopProvider` and `TopModel` for app-level state.
- `MoLcWidget` for pairing a page model with page logic.
- `ModelWidget` and `LogicWidget` for model-only and logic-only sections.
- `EventModel` and `EventConsumerMixin` for event-scoped refresh.
- `ExposedMixin` and `find<T>()` for looking up active objects.
- `Mutable<T>` and `MutableWidget` for local reactive values.
- `NoMoWidget` for simple temporary value state.

Run it from the repository root with:

```bash
cd example
flutter run
```
