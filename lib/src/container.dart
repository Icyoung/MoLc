import 'event.dart';
import 'exposed.dart';
import 'top.dart';

/// Internal container that holds [ExposedMixin] registrations and [EventModel] listeners.
///
/// Automatically registered by [TopProvider]. Do not create manually.
class CoreContainer extends TopModel
    with ExposedContainerMixin, EventContainerMixin {}