import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/stats/domain/usecases/stats_usecases.dart';
import 'package:habit_tracker/features/tracking/domain/usecases/get_habit_calendar_data.dart';
import 'package:habit_tracker/features/stats/presentation/bloc/stats_event.dart';
import 'package:habit_tracker/features/stats/presentation/bloc/stats_state.dart';

export 'package:habit_tracker/features/stats/presentation/bloc/stats_event.dart';
export 'package:habit_tracker/features/stats/presentation/bloc/stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final GetHabitStats getHabitStats;
  final GetGlobalStats getGlobalStats;
  final GetHabitCalendarData getHabitCalendarData;

  StatsBloc({
    required this.getHabitStats,
    required this.getGlobalStats,
    required this.getHabitCalendarData,
  }) : super(StatsInitial()) {
    on<LoadHabitStats>(_onLoadHabitStats);
    on<LoadGlobalStats>(_onLoadGlobalStats);
    on<LoadHeatMap>(_onLoadHeatMap);
  }

  Future<void> _onLoadHabitStats(
    LoadHabitStats event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsLoaded) {
      emit(StatsLoading());
    }
    final result = await getHabitStats(event.habitId);
    result.fold((failure) => emit(StatsError(failure.message)), (stats) {
      if (state is StatsLoaded) {
        emit((state as StatsLoaded).copyWith(stats: stats));
      } else {
        emit(StatsLoaded(stats: stats));
      }
    });
  }

  Future<void> _onLoadGlobalStats(
    LoadGlobalStats event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsLoaded) {
      emit(StatsLoading());
    }
    final result = await getGlobalStats(NoParams());
    result.fold((failure) => emit(StatsError(failure.message)), (globalStats) {
      if (state is StatsLoaded) {
        emit((state as StatsLoaded).copyWith(globalStats: globalStats));
      } else {
        emit(StatsLoaded(globalStats: globalStats));
      }
    });
  }

  Future<void> _onLoadHeatMap(
    LoadHeatMap event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsLoaded) {
      emit(StatsLoading());
    }

    // Default to last 90 days if not provided
    final end = event.endDate ?? DateTime.now();
    final start = event.startDate ?? end.subtract(const Duration(days: 90));

    final result = await getHabitCalendarData(
      GetHabitCalendarDataParams(
        startDate: start,
        endDate: end,
        habitId: event.habitId,
      ),
    );
    result.fold((failure) => emit(StatsError(failure.message)), (data) {
      if (state is StatsLoaded) {
        emit((state as StatsLoaded).copyWith(heatMapData: data));
      } else {
        emit(StatsLoaded(heatMapData: data));
      }
    });
  }
}

class StatsError extends StatsState {
  final String message;
  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}
