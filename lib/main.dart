import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'injection_container.dart' as di;
import 'core/constants/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/habit/presentation/bloc/habit_bloc.dart';
import 'features/tracking/presentation/bloc/tracking_bloc.dart';
import 'features/stats/presentation/bloc/stats_bloc.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  // Initialize Dependency Injection
  await di.init();

  // Initialize and request notification permissions
  final notificationService = di.sl<NotificationService>();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => di.sl<HabitBloc>()),
        BlocProvider(
          create: (_) =>
              di.sl<TrackingBloc>()..add(LoadTrackingForDate(DateTime.now())),
        ),
        BlocProvider(create: (_) => di.sl<StatsBloc>()),
        BlocProvider(create: (_) => di.sl<CategoryBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Habit Tracker',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
