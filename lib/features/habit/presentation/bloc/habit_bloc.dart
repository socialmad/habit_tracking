import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/habit/domain/usecases/habit_usecases.dart';

import 'package:habit_tracker/core/services/persistence_service.dart';
import 'package:habit_tracker/core/services/notification_service.dart';

part 'habit_event.dart';
part 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final GetHabits getHabits;
  final AddHabit addHabit;
  final UpdateHabit updateHabit;
  final DeleteHabit deleteHabit;
  final PersistenceService persistenceService;
  final NotificationService notificationService;

  HabitBloc({
    required this.getHabits,
    required this.addHabit,
    required this.updateHabit,
    required this.deleteHabit,
    required this.persistenceService,
    required this.notificationService,
  }) : super(HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<AddHabitEvent>(_onAddHabit);
    on<UpdateHabitEvent>(_onUpdateHabit);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<SearchHabits>(_onSearchHabits);
    on<FilterHabits>(_onFilterHabits);
    on<SortHabits>(_onSortHabits);
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    String? currentCategoryId;
    if (state is HabitLoaded) {
      currentCategoryId = (state as HabitLoaded).filterCategoryId;
    }
    final targetCategoryId = event.updateCategory
        ? event.categoryId
        : currentCategoryId;

    emit(HabitLoading());
    final result = await getHabits(NoParams());

    // Load preferences
    final sortOption = persistenceService.getSortOption();
    final filterPrefs = persistenceService.getFilterPreferences();
    final freqString = filterPrefs['frequency'] as String?;
    final frequency = freqString != null
        ? HabitFrequency.values.firstWhere((e) => e.toString() == freqString)
        : null;

    result.fold(
      (failure) => emit(HabitError(failure.message)),
      (habits) => emit(
        HabitLoaded(
          habits: habits,
          filteredHabits: _applyFilters(
            habits,
            '',
            targetCategoryId,
            frequency,
            filterPrefs['archived'] as bool?,
            filterPrefs['onlyActiveStreaks'] as bool?,
            sortOption,
          ),
          filterCategoryId: targetCategoryId,
          filterFrequency: frequency,
          filterArchived: filterPrefs['archived'] as bool?,
          filterOnlyActiveStreaks: filterPrefs['onlyActiveStreaks'] as bool?,
          sortOption: sortOption,
        ),
      ),
    );
  }

  void _onSearchHabits(SearchHabits event, Emitter<HabitState> emit) {
    if (state is HabitLoaded) {
      final s = state as HabitLoaded;
      persistenceService.addSearchQuery(event.query);
      emit(
        s.copyWith(
          searchQuery: event.query,
          filteredHabits: _applyFilters(
            s.habits,
            event.query,
            s.filterCategoryId,
            s.filterFrequency,
            s.filterArchived,
            s.filterOnlyActiveStreaks,
            s.sortOption,
          ),
        ),
      );
    }
  }

  Future<void> _onFilterHabits(
    FilterHabits event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final s = state as HabitLoaded;

      await persistenceService.saveFilterPreferences(
        frequency: event.frequency?.toString(),
        archived: event.archived,
        onlyActiveStreaks: event.onlyActiveStreaks,
      );

      emit(
        s.copyWith(
          filterCategoryId: event.categoryId,
          filterFrequency: event.frequency,
          filterArchived: event.archived,
          filterOnlyActiveStreaks: event.onlyActiveStreaks,
          filteredHabits: _applyFilters(
            s.habits,
            s.searchQuery,
            event.categoryId,
            event.frequency,
            event.archived,
            event.onlyActiveStreaks,
            s.sortOption,
          ),
        ),
      );
    }
  }

  Future<void> _onSortHabits(SortHabits event, Emitter<HabitState> emit) async {
    if (state is HabitLoaded) {
      final s = state as HabitLoaded;
      await persistenceService.saveSortOption(event.sortOption);
      emit(
        s.copyWith(
          sortOption: event.sortOption,
          filteredHabits: _applyFilters(
            s.habits,
            s.searchQuery,
            s.filterCategoryId,
            s.filterFrequency,
            s.filterArchived,
            s.filterOnlyActiveStreaks,
            event.sortOption,
          ),
        ),
      );
    }
  }

  List<HabitEntity> _applyFilters(
    List<HabitEntity> habits,
    String query,
    String? categoryId,
    HabitFrequency? frequency,
    bool? archived,
    bool? onlyActiveStreaks,
    HabitSortOption sortOption,
  ) {
    var filtered = List<HabitEntity>.from(habits);

    // Search
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered
          .where(
            (h) =>
                h.name.toLowerCase().contains(q) ||
                h.description.toLowerCase().contains(q),
          )
          .toList();
    }

    // Category
    if (categoryId != null) {
      filtered = filtered.where((h) => h.categoryId == categoryId).toList();
    }

    // Frequency
    if (frequency != null) {
      filtered = filtered.where((h) => h.frequency == frequency).toList();
    }

    // Archived status (null means all, true means only archived, false means only active)
    if (archived != null) {
      filtered = filtered.where((h) => h.archived == archived).toList();
    }

    // Active Streaks
    if (onlyActiveStreaks == true) {
      filtered = filtered.where((h) => h.currentStreak > 0).toList();
    }

    // Sorting
    switch (sortOption) {
      case HabitSortOption.recentlyAdded:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HabitSortOption.nameAZ:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case HabitSortOption.currentStreak:
        filtered.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
        break;
      case HabitSortOption.completionRate:
        // For now using longestStreak as a proxy if completionRate is not yet in entity
        filtered.sort((a, b) => b.longestStreak.compareTo(a.longestStreak));
        break;
      case HabitSortOption.category:
        filtered.sort(
          (a, b) => (a.categoryId ?? '').compareTo(b.categoryId ?? ''),
        );
        break;
      case HabitSortOption.custom:
        // To be implemented with drag and drop
        break;
    }

    return filtered;
  }

  Future<void> _onAddHabit(
    AddHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    // Optimistic update could be complex here, so we stick to simple loading for now
    emit(HabitLoading());
    final result = await addHabit(event.habit);
    result.fold((failure) => emit(HabitError(failure.message)), (habit) {
      if (habit.reminderEnabled) {
        notificationService.scheduleHabitReminder(habit);
      } else {
        notificationService.cancelHabitReminder(habit.id);
      }
      add(LoadHabits());
    });
  }

  Future<void> _onUpdateHabit(
    UpdateHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    emit(HabitLoading());
    final result = await updateHabit(event.habit);
    result.fold((failure) => emit(HabitError(failure.message)), (_) {
      if (event.habit.reminderEnabled) {
        notificationService.scheduleHabitReminder(event.habit);
      } else {
        notificationService.cancelHabitReminder(event.habit.id);
      }
      add(LoadHabits());
    });
  }

  Future<void> _onDeleteHabit(
    DeleteHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    emit(HabitLoading());

    // Cancel notifications for this habit
    await notificationService.cancelHabitReminder(event.habitId);

    final result = await deleteHabit(event.habitId);
    result.fold(
      (failure) => emit(HabitError(failure.message)),
      (_) => add(LoadHabits()),
    );
  }
}
