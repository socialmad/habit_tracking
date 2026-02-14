part of 'habit_bloc.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();
  @override
  List<Object?> get props => [];
}

class LoadHabits extends HabitEvent {
  final String? categoryId;
  final bool updateCategory;
  const LoadHabits({this.categoryId, this.updateCategory = false});
  @override
  List<Object?> get props => [categoryId, updateCategory];
}

class AddHabitEvent extends HabitEvent {
  final HabitEntity habit;
  const AddHabitEvent(this.habit);
  @override
  List<Object> get props => [habit];
}

class UpdateHabitEvent extends HabitEvent {
  final HabitEntity habit;
  const UpdateHabitEvent(this.habit);
  @override
  List<Object> get props => [habit];
}

class DeleteHabitEvent extends HabitEvent {
  final String habitId;
  const DeleteHabitEvent(this.habitId);
  @override
  List<Object> get props => [habitId];
}

class SearchHabits extends HabitEvent {
  final String query;
  const SearchHabits(this.query);
  @override
  List<Object> get props => [query];
}

class FilterHabits extends HabitEvent {
  final String? categoryId;
  final HabitFrequency? frequency;
  final bool? archived;
  final bool? onlyActiveStreaks;

  const FilterHabits({
    this.categoryId,
    this.frequency,
    this.archived,
    this.onlyActiveStreaks,
  });

  @override
  List<Object?> get props => [
    categoryId,
    frequency,
    archived,
    onlyActiveStreaks,
  ];
}

class SortHabits extends HabitEvent {
  final HabitSortOption sortOption;
  const SortHabits(this.sortOption);
  @override
  List<Object> get props => [sortOption];
}
