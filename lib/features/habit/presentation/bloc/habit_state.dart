part of 'habit_bloc.dart';

abstract class HabitState extends Equatable {
  const HabitState();
  @override
  List<Object?> get props => [];
}

class HabitInitial extends HabitState {}

class HabitLoading extends HabitState {}

class HabitLoaded extends HabitState {
  final List<HabitEntity> habits; // The full list
  final List<HabitEntity> filteredHabits; // The list to display
  final String searchQuery;
  final String? filterCategoryId;
  final HabitFrequency? filterFrequency;
  final bool? filterArchived;
  final bool? filterOnlyActiveStreaks;
  final HabitSortOption sortOption;

  const HabitLoaded({
    required this.habits,
    required this.filteredHabits,
    this.searchQuery = '',
    this.filterCategoryId,
    this.filterFrequency,
    this.filterArchived,
    this.filterOnlyActiveStreaks,
    this.sortOption = HabitSortOption.recentlyAdded,
  });

  HabitLoaded copyWith({
    List<HabitEntity>? habits,
    List<HabitEntity>? filteredHabits,
    String? searchQuery,
    String? filterCategoryId,
    HabitFrequency? filterFrequency,
    bool? filterArchived,
    bool? filterOnlyActiveStreaks,
    HabitSortOption? sortOption,
  }) {
    return HabitLoaded(
      habits: habits ?? this.habits,
      filteredHabits: filteredHabits ?? this.filteredHabits,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategoryId: filterCategoryId ?? this.filterCategoryId,
      filterFrequency: filterFrequency ?? this.filterFrequency,
      filterArchived: filterArchived ?? this.filterArchived,
      filterOnlyActiveStreaks:
          filterOnlyActiveStreaks ?? this.filterOnlyActiveStreaks,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [
    habits,
    filteredHabits,
    searchQuery,
    filterCategoryId,
    filterFrequency,
    filterArchived,
    filterOnlyActiveStreaks,
    sortOption,
  ];
}

class HabitError extends HabitState {
  final String message;
  const HabitError(this.message);
  @override
  List<Object> get props => [message];
}
