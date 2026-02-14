import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection_container.dart' as di;
import 'package:habit_tracker/features/stats/presentation/bloc/stats_bloc.dart';

import 'package:habit_tracker/features/splash/presentation/pages/splash_page.dart';
import 'package:habit_tracker/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:habit_tracker/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:habit_tracker/core/widgets/main_wrapper.dart';
import 'package:habit_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:habit_tracker/features/auth/presentation/pages/signup_page.dart';
import 'package:habit_tracker/features/habit/presentation/pages/home_page.dart';
import 'package:habit_tracker/features/habit/presentation/pages/add_habit_page.dart';
import 'package:habit_tracker/features/stats/presentation/pages/stats_page.dart';
import 'package:habit_tracker/features/categories/presentation/pages/categories_page.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';
import 'package:habit_tracker/features/categories/presentation/pages/create_category_page.dart';
import 'package:habit_tracker/features/habit/presentation/pages/habit_details_page.dart';
import 'package:habit_tracker/features/habit/presentation/pages/edit_habit_page.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

    // Authenticated Routes
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                final categoryId = state.extra as String?;
                return HomePage(initialCategoryId: categoryId);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesPage(),
            ),
            GoRoute(
              path: '/create-category',
              builder: (context, state) {
                final category = state.extra as CategoryEntity?;
                return CreateCategoryPage(category: category);
              },
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/add-habit',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddHabitPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/habit-details',
      pageBuilder: (context, state) {
        final habit = state.extra as HabitEntity;
        return CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => di.sl<StatsBloc>()
              ..add(LoadHabitStats(habit.id))
              ..add(LoadHeatMap(habitId: habit.id)),
            child: HabitDetailsPage(habit: habit),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/edit-habit',
      pageBuilder: (context, state) {
        final habit = state.extra as HabitEntity;
        return CustomTransitionPage(
          key: state.pageKey,
          child: EditHabitPage(habit: habit),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
