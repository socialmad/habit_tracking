part of 'tracking_bloc.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object> get props => [];
}

class LoadTrackingForDate extends TrackingEvent {
  final DateTime date;
  const LoadTrackingForDate(this.date);
  @override
  List<Object> get props => [date];
}

class ToggleHabitCompletion extends TrackingEvent {
  final String habitId;
  const ToggleHabitCompletion(this.habitId);
  @override
  List<Object> get props => [habitId];
}
