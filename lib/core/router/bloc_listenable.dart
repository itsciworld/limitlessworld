import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a bloc's state stream to the [Listenable] that go_router's
/// `refreshListenable` expects, so the redirect re-runs on every auth change.
class BlocListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  BlocListenable(Stream<dynamic> stream) {
    // Fire once up front so a router built after the bloc already settled
    // still evaluates against the current state.
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
