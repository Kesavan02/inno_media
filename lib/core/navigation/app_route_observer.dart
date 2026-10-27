import 'package:flutter/material.dart';

/// Global RouteObserver to track page navigation routes across the app.
/// Used to notify widgets (like Reels) when new routes are pushed or popped above them.
final RouteObserver<PageRoute<dynamic>> appRouteObserver = RouteObserver<PageRoute<dynamic>>();
