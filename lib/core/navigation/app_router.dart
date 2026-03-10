import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_storage_analyzer/features/splash/splash_screen.dart';
import 'package:smart_storage_analyzer/features/onboarding/onboarding_screen.dart';
import 'package:smart_storage_analyzer/features/dashboard/dashboard_screen.dart';
import 'package:smart_storage_analyzer/features/storage_analysis/storage_categories_screen.dart';
import 'package:smart_storage_analyzer/features/storage_analysis/category_detail_screen.dart';
import 'package:smart_storage_analyzer/features/large_files/large_files_screen.dart';
import 'package:smart_storage_analyzer/features/duplicate_finder/duplicate_finder_screen.dart';
import 'package:smart_storage_analyzer/features/app_usage/app_usage_screen.dart';
import 'package:smart_storage_analyzer/features/cleaner/cleaner_screen.dart';
import 'package:smart_storage_analyzer/features/settings/settings_screen.dart';

final routerProvider = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const StorageCategoriesScreen(),
      ),
    ),
    GoRoute(
      path: '/category/:name',
      pageBuilder: (context, state) => _slideTransition(
        state,
        CategoryDetailScreen(category: state.pathParameters['name']!),
      ),
    ),
    GoRoute(
      path: '/large-files',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const LargeFilesScreen(),
      ),
    ),
    GoRoute(
      path: '/duplicates',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const DuplicateFinderScreen(),
      ),
    ),
    GoRoute(
      path: '/app-usage',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const AppUsageScreen(),
      ),
    ),
    GoRoute(
      path: '/cleaner',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const CleanerScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _slideTransition(
        state,
        const SettingsScreen(),
      ),
    ),
  ],
);

CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
