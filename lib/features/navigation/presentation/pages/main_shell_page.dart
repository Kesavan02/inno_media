import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/navigation/app_navigation_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_landing_indexed_stack.dart';
import '../../../dynamic_form/presentation/pages/dynamic_form_page.dart';
import '../../../feed/presentation/pages/feed_page.dart';
import '../../../reels/presentation/pages/reels_page.dart';
import 'profile_tab.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final List<int> _navigationStack = [0];
  double _horizontalDragDistance = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreCachedScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // User paused or minimized the app: cache the active screen immediately
      _cacheCurrentScreen();
    } else if (state == AppLifecycleState.resumed) {
      // User resumed the app: ensure active screen and state are maintained
      _onAppResumed();
    }
  }

  /// Caches the current screen index and navigation stack into SharedPreferences
  Future<void> _cacheCurrentScreen() async {
    try {
      final sp = di.sl.isRegistered<SharedPreferences>()
          ? di.sl<SharedPreferences>()
          : await SharedPreferences.getInstance();
      await sp.setInt(AppConstants.keyLastActiveTab, _currentIndex);
      final stackJson = jsonEncode(_navigationStack);
      await sp.setString(AppConstants.keyLastNavigationStack, stackJson);
      debugPrint('[MainShellPage] Screen cached: $_currentIndex (stack: $_navigationStack)');
    } catch (e) {
      debugPrint('[MainShellPage] Error caching screen: $e');
    }
  }

  /// Restores the last active screen and navigation stack from SharedPreferences
  Future<void> _restoreCachedScreen() async {
    try {
      final sp = di.sl.isRegistered<SharedPreferences>()
          ? di.sl<SharedPreferences>()
          : await SharedPreferences.getInstance();
      final savedIndex = sp.getInt(AppConstants.keyLastActiveTab);
      final savedStackJson = sp.getString(AppConstants.keyLastNavigationStack);

      if (savedIndex != null && savedIndex >= 0 && savedIndex < 4) {
        List<int> restoredStack = [0];
        if (savedIndex == 0) {
          // If restored to Home screen, backstack is erased to root [0]
          restoredStack = [0];
        } else {
          if (savedStackJson != null) {
            try {
              final decoded = jsonDecode(savedStackJson) as List<dynamic>;
              final list = decoded
                  .map((e) => (e as num).toInt())
                  .where((i) => i >= 0 && i < 4)
                  .toList();
              if (list.isNotEmpty) {
                restoredStack = list;
              }
            } catch (_) {}
          }
          if (restoredStack.isEmpty || restoredStack.last != savedIndex) {
            restoredStack.add(savedIndex);
          }
        }

        if (mounted) {
          setState(() {
            _currentIndex = savedIndex;
            _navigationStack
              ..clear()
              ..addAll(restoredStack);
          });
          debugPrint('[MainShellPage] Restored screen to: $_currentIndex (stack: $_navigationStack)');
        }
      }
    } catch (e) {
      debugPrint('[MainShellPage] Error restoring screen: $e');
    }
  }

  void _onAppResumed() {
    debugPrint('[MainShellPage] Resumed app on active screen: $_currentIndex');
    // Ensure screen is verified upon resumption
    _restoreCachedScreen();
  }

  void _navigateTo(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        // User returned to Home / Feed screen: erase the navigation back stack
        _navigationStack
          ..clear()
          ..add(0);
        debugPrint('[MainShellPage] Navigated to Home screen: backstack erased.');
      } else {
        _navigationStack.add(index);
        // Bound history stack to last 50 items to prevent unbounded growth
        if (_navigationStack.length > 50) {
          _navigationStack.removeAt(1);
        }
      }
    });
    _cacheCurrentScreen();
  }

  bool _backtrack() {
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
        _currentIndex = _navigationStack.last;
        if (_currentIndex == 0) {
          // Backtracking reached the Home screen: erase the stack so only root [0] remains
          _navigationStack
            ..clear()
            ..add(0);
          debugPrint('[MainShellPage] Backtracking reached Home screen: backstack erased.');
        }
      });
      _cacheCurrentScreen();
      return true;
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    final isReelsActive = _currentIndex == 1;
    final canBacktrack = _navigationStack.length > 1;

    return AppNavigationScope(
      currentIndex: _currentIndex,
      navigationStack: List.unmodifiable(_navigationStack),
      navigateTo: _navigateTo,
      backtrack: _backtrack,
      canBacktrack: canBacktrack,
      child: PopScope(
        canPop: !canBacktrack,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _backtrack();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _horizontalDragDistance = 0.0;
            },
            onHorizontalDragUpdate: (details) {
              _horizontalDragDistance += details.primaryDelta ?? 0;
            },
            onHorizontalDragCancel: () {
              _horizontalDragDistance = 0.0;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              const double velocityThreshold = 250.0;
              const double distanceThreshold = 60.0;

              if (velocity < -velocityThreshold || _horizontalDragDistance < -distanceThreshold) {
                // Slid Left -> Route to Next bottom navbar screen: (currentIndex + 1) % 4
                final nextIndex = (_currentIndex + 1) % 4;
                _navigateTo(nextIndex);
              } else if (velocity > velocityThreshold || _horizontalDragDistance > distanceThreshold) {
                // Slid Right -> Route to Previous bottom navbar screen
                final prevIndex = (_currentIndex - 1 + 4) % 4;
                if (_navigationStack.length > 1 &&
                    _navigationStack[_navigationStack.length - 2] == prevIndex) {
                  _backtrack();
                } else {
                  _navigateTo(prevIndex);
                }
              }
              _horizontalDragDistance = 0.0;
            },
            child: AnimatedLandingIndexedStack(
              index: _currentIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              children: [
                const FeedPage(),
                ReelsPage(isTabActive: isReelsActive),
                const DynamicFormPage(),
                const ProfileTab(),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isReelsActive ? Colors.black.withOpacity(0.95) : AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Feed'),
                    _buildNavItem(1, Icons.play_circle_fill_rounded, Icons.play_circle_outline_rounded, 'Reels'),
                    _buildNavItem(2, Icons.dynamic_form_rounded, Icons.dynamic_form_outlined, 'Dynamic Form'),
                    _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final tabKey = 'tab_${label.toLowerCase().replaceAll(' ', '_')}';

    return GestureDetector(
      key: Key(tabKey),
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.24), width: 1.0)
              : Border.all(color: Colors.transparent, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

