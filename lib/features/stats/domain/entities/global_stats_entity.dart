import 'package:equatable/equatable.dart';

class GlobalStatsEntity extends Equatable {
  final int completedToday;
  final int totalHabitsToday;
  final double todayCompletionRate;

  final int currentWeekCompletions;
  final int lastWeekCompletions;
  final double
  weeklyTrendPercentage; // Positive for improvement, negative for decline

  final int bestStreakThisMonth;
  final String mostConsistentHabit;
  final int totalMonthCompletions;
  final int fullCompletionDays; // Days where 100% habits were completed

  final List<String> insights;

  const GlobalStatsEntity({
    required this.completedToday,
    required this.totalHabitsToday,
    required this.todayCompletionRate,
    required this.currentWeekCompletions,
    required this.lastWeekCompletions,
    required this.weeklyTrendPercentage,
    required this.bestStreakThisMonth,
    required this.mostConsistentHabit,
    required this.totalMonthCompletions,
    required this.fullCompletionDays,
    required this.insights,
  });

  @override
  List<Object?> get props => [
    completedToday,
    totalHabitsToday,
    todayCompletionRate,
    currentWeekCompletions,
    lastWeekCompletions,
    weeklyTrendPercentage,
    bestStreakThisMonth,
    mostConsistentHabit,
    totalMonthCompletions,
    fullCompletionDays,
    insights,
  ];
}
