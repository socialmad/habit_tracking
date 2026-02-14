part of 'tracking_bloc.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();
  @override
  List<Object> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingLoaded extends TrackingState {
  final DateTime date;
  final Set<String> completedHabitIds;
  final Map<String, int> habitWeeklyProgress;

  const TrackingLoaded({
    required this.date,
    required this.completedHabitIds,
    this.habitWeeklyProgress = const {},
  });

  @override
  List<Object> get props => [date, completedHabitIds, habitWeeklyProgress];
}

class TrackingError extends TrackingState {
  final String message;
  const TrackingError(this.message);
  @override
  List<Object> get props => [message];
}
