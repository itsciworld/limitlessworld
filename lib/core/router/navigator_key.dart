import 'package:flutter/widgets.dart';

/// The app's root navigator.
///
/// Lives in its own file so both the router and context-free helpers (toasts)
/// can reach it without importing each other.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
