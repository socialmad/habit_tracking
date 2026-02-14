import 'package:equatable/equatable.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();
  @override
  List<Object?> get props => [];
}

class LoadHabitStats extends StatsEvent {
  final String habitId;
  const LoadHabitStats(this.habitId);
  @override
  List<Object> get props => [habitId];
}

class LoadGlobalStats extends StatsEvent {}

class LoadHeatMap extends StatsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? habitId;

  const LoadHeatMap({this.startDate, this.endDate, this.habitId});

  @override
  List<Object?> get props => [startDate, endDate, habitId];
}
