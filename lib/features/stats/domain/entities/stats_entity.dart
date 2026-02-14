import 'package:equatable/equatable.dart';
import 'package:habit_tracker/features/stats/domain/entities/milestone_entity.dart';

class StatsEntity extends Equatable {
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;

  // Advanced Stats
  final String bestDayOfWeek;
  final double currentWeekProgress;
  final Map<DateTime, int> streaksOverTime; // Date -> Streak on that date
  final Map<int, int> completionsPerWeek; // Week number/Index -> Count
  final Map<int, int> completionsByDayOfWeek; // 1 (Mon) - 7 (Sun) -> Count
  final List<MilestoneEntity> milestones;

  const StatsEntity({
    required this.totalCompletions,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.bestDayOfWeek,
    required this.currentWeekProgress,
    required this.streaksOverTime,
    required this.completionsPerWeek,
    required this.completionsByDayOfWeek,
    required this.milestones,
  });

  @override
  List<Object?> get props => [
    totalCompletions,
    currentStreak,
    longestStreak,
    completionRate,
    bestDayOfWeek,
    currentWeekProgress,
    streaksOverTime,
    completionsPerWeek,
    completionsByDayOfWeek,
    milestones,
  ];
}
