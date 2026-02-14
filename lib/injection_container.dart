import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/core/services/motivation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/habit/presentation/bloc/habit_bloc.dart';
import 'features/habit/domain/usecases/habit_usecases.dart';
import 'features/habit/domain/repositories/habit_repository.dart';
import 'features/habit/data/repositories/habit_repository_impl.dart';
import 'features/tracking/presentation/bloc/tracking_bloc.dart';
import 'features/tracking/domain/usecases/tracking_usecases.dart';
import 'features/tracking/domain/usecases/get_habit_calendar_data.dart';
import 'features/tracking/domain/repositories/tracking_repository.dart';
import 'features/tracking/data/repositories/tracking_repository_impl.dart';
import 'features/stats/presentation/bloc/stats_bloc.dart';
import 'features/stats/domain/usecases/stats_usecases.dart';
import 'features/stats/domain/repositories/stats_repository.dart';
import 'features/stats/data/repositories/stats_repository_impl.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/categories/domain/usecases/category_usecases.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/categories/data/repositories/category_repository_impl.dart';

import 'package:habit_tracker/core/services/persistence_service.dart';
import 'package:habit_tracker/core/services/notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => PersistenceService(sl()));
  sl.registerLazySingleton(() => MotivationService());
  sl.registerLazySingleton(() => NotificationService());

  // ! External
  // Supabase client is initialized in main.dart, but we can register the instance here if needed
  // For now we will access it via Supabase.instance.client or register it after initialization
  sl.registerLazySingleton(() => Supabase.instance.client);

  // ! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      getCurrentUser: sl(),
      resetPassword: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // ! Features - Habit
  // Bloc
  sl.registerFactory(
    () => HabitBloc(
      getHabits: sl(),
      addHabit: sl(),
      updateHabit: sl(),
      deleteHabit: sl(),
      persistenceService: sl(),
      notificationService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetHabits(sl()));
  sl.registerLazySingleton(() => AddHabit(sl()));
  sl.registerLazySingleton(() => UpdateHabit(sl()));
  sl.registerLazySingleton(() => DeleteHabit(sl()));

  // Repository
  sl.registerLazySingleton<HabitRepository>(() => HabitRepositoryImpl(sl()));

  // ! Features - Tracking
  // Bloc
  sl.registerFactory(
    () => TrackingBloc(
      getCompletionsForDate: sl(),
      completeHabit: sl(),
      uncompleteHabit: sl(),
      getCompletionsForDateRange: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCompletionsForDate(sl()));
  sl.registerLazySingleton(() => CompleteHabit(sl()));
  sl.registerLazySingleton(() => UncompleteHabit(sl()));
  sl.registerLazySingleton(() => GetCompletionsForDateRange(sl()));

  // Repository
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(sl()),
  );

  // ! Features - Stats
  // Bloc
  sl.registerFactory(
    () => StatsBloc(
      getHabitStats: sl(),
      getGlobalStats: sl(),
      getHabitCalendarData: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetHabitStats(sl()));
  sl.registerLazySingleton(() => GetGlobalStats(sl()));
  sl.registerLazySingleton(() => GetHabitCalendarData(sl()));

  // Repository
  sl.registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(sl()));

  // ! Features - Categories
  // Bloc
  sl.registerFactory(
    () => CategoryBloc(
      getCategories: sl(),
      addCategory: sl(),
      deleteCategory: sl(),
      seedCategories: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => AddCategory(sl()));
  sl.registerLazySingleton(() => DeleteCategory(sl()));
  sl.registerLazySingleton(() => SeedCategories(sl()));

  // Repository
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );
}
