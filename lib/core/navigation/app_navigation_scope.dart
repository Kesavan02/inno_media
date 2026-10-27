import 'package:flutter/material.dart';

/// InheritedWidget that provides the app-wide tab navigation stack and backtracking controls.
/// Maintains the user's sequential history stack (e.g. Feed -> Reels -> Dynamic Form -> Profile)
/// and allows backtracking in reverse order on every back navigation event.
class AppNavigationScope extends InheritedWidget {
  final int currentIndex;
  final List<int> navigationStack;
  final void Function(int index) navigateTo;
  final bool Function() backtrack;
  final bool canBacktrack;

  const AppNavigationScope({
    super.key,
    required this.currentIndex,
    required this.navigationStack,
    required this.navigateTo,
    required this.backtrack,
    required this.canBacktrack,
    required super.child,
  });

  static AppNavigationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigationScope>();
  }

  @override
  bool updateShouldNotify(AppNavigationScope oldWidget) {
    return currentIndex != oldWidget.currentIndex ||
        navigationStack.length != oldWidget.navigationStack.length ||
        canBacktrack != oldWidget.canBacktrack;
  }
}
