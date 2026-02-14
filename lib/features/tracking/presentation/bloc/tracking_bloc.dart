import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_tracker/features/tracking/domain/usecases/tracking_usecases.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final GetCompletionsForDate getCompletionsForDate;
  final CompleteHabit completeHabit;
  final UncompleteHabit uncompleteHabit;
  final GetCompletionsForDateRange getCompletionsForDateRange;

  TrackingBloc({
    required this.getCompletionsForDate,
    required this.completeHabit,
    required this.uncompleteHabit,
    required this.getCompletionsForDateRange,
  }) : super(TrackingInitial()) {
    on<LoadTrackingForDate>(_onLoadTrackingForDate);
    on<ToggleHabitCompletion>(_onToggleHabitCompletion);
  }

  Future<void> _onLoadTrackingForDate(
    LoadTrackingForDate event,
    Emitter<TrackingState> emit,
  ) async {
    emit(TrackingLoading());

    // 1. Fetch completions for the specific date
    final dailyResult = await getCompletionsForDate(event.date);

    // 2. Fetch completions for the current week (Mon-Sun)
    final now = event.date;
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weeklyResult = await getCompletionsForDateRange(
      DateRangeParams(startDate: startOfWeek, endDate: endOfWeek),
    );

    dailyResult.fold((failure) => emit(TrackingError(failure.message)), (
      completedIds,
    ) {
      weeklyResult.fold((failure) => emit(TrackingError(failure.message)), (
        weeklyData,
      ) {
        // Process weekly counts
        final Map<String, int> weeklyCounts = {};
        for (final entry in weeklyData) {
          final habitId = entry['habit_id'] as String;
          weeklyCounts[habitId] = (weeklyCounts[habitId] ?? 0) + 1;
        }

        emit(
          TrackingLoaded(
            date: event.date,
            completedHabitIds: Set.from(completedIds),
            habitWeeklyProgress: weeklyCounts,
          ),
        );
      });
    });
  }

  Future<void> _onToggleHabitCompletion(
    ToggleHabitCompletion event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is TrackingLoaded) {
      final isCompleted = currentState.completedHabitIds.contains(
        event.habitId,
      );
      final newSet = Set<String>.from(currentState.completedHabitIds);
      final newWeeklyCounts = Map<String, int>.from(
        currentState.habitWeeklyProgress,
      );

      // Optimistic update
      if (isCompleted) {
        newSet.remove(event.habitId);
        newWeeklyCounts[event.habitId] =
            (newWeeklyCounts[event.habitId] ?? 1) - 1;
      } else {
        newSet.add(event.habitId);
        newWeeklyCounts[event.habitId] =
            (newWeeklyCounts[event.habitId] ?? 0) + 1;
      }
      emit(
        TrackingLoaded(
          date: currentState.date,
          completedHabitIds: newSet,
          habitWeeklyProgress: newWeeklyCounts,
        ),
      );

      final params = CompletionParams(
        habitId: event.habitId,
        date: currentState.date,
      );
      final result = isCompleted
          ? await uncompleteHabit(params)
          : await completeHabit(params);

      result.fold(
        (failure) {
          // Revert on failure
          emit(TrackingError(failure.message));
          add(LoadTrackingForDate(currentState.date));
        },
        (_) => null, // Success, state already updated optimistically
      );
    }
  }
}
