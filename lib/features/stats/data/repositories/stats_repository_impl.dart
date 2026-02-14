import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/features/stats/domain/entities/global_stats_entity.dart';
import 'package:habit_tracker/features/stats/domain/entities/stats_entity.dart';
import 'package:habit_tracker/features/stats/domain/entities/milestone_entity.dart';
import 'package:habit_tracker/features/stats/domain/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  final SupabaseClient supabaseClient;

  StatsRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Failure, StatsEntity>> getStatsForHabit(String habitId) async {
    try {
      final response = await supabaseClient
          .from('habit_completions')
          .select('completed_date')
          .eq('habit_id', habitId)
          .order('completed_date', ascending: true);

      final dates = (response as List)
          .map((e) => DateTime.parse(e['completed_date'] as String))
          .toList();

      if (dates.isEmpty) {
        return const Right(
          StatsEntity(
            totalCompletions: 0,
            currentStreak: 0,
            longestStreak: 0,
            completionRate: 0,
            bestDayOfWeek: 'None',
            currentWeekProgress: 0,
            streaksOverTime: {},
            completionsPerWeek: {},
            completionsByDayOfWeek: {},
            milestones: [],
          ),
        );
      }

      // Fetch habit creation date
      final habitData = await supabaseClient
          .from('habits')
          .select('created_at')
          .eq('id', habitId)
          .single();
      final createdAt = DateTime.parse(habitData['created_at']);

      final total = dates.length;
      final currentStreak = _calculateCurrentStreak(dates);
      final longestStreak = _calculateLongestStreak(dates);

      final streaksOverTime = _calculateStreaksOverTime(dates);
      final completionsPerWeek = _calculateCompletionsPerWeek(dates);
      final completionsByDayOfWeek = _calculateCompletionsByDayOfWeek(dates);
      final bestDayOfWeek = _calculateBestDayOfWeek(completionsByDayOfWeek);
      final currentWeekProgress = _calculateCurrentWeekProgress(dates);
      final milestones = _calculateMilestones(
        dates,
        currentStreak,
        longestStreak,
      );

      // Calculate rate based on creation date
      final now = DateTime.now();
      final daysSinceCreation = now.difference(createdAt).inDays + 1;
      final completionRate = daysSinceCreation > 0
          ? total / daysSinceCreation
          : 0.0;

      return Right(
        StatsEntity(
          totalCompletions: total,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          completionRate: completionRate,
          bestDayOfWeek: bestDayOfWeek,
          currentWeekProgress: currentWeekProgress,
          streaksOverTime: streaksOverTime,
          completionsPerWeek: completionsPerWeek,
          completionsByDayOfWeek: completionsByDayOfWeek,
          milestones: milestones,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GlobalStatsEntity>> getGlobalStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 1. Fetch Today's Progress
      final habitsResponse = await supabaseClient
          .from('habits')
          .select('id, name')
          .eq('archived', false);
      final allHabits = habitsResponse as List;

      final completionsTodayResponse = await supabaseClient
          .from('habit_completions')
          .select('habit_id')
          .eq('completed_date', today.toIso8601String().split('T')[0]);
      final completedTodayIds = (completionsTodayResponse as List)
          .map((e) => e['habit_id'] as String)
          .toSet();

      final completedToday = completedTodayIds.length;
      final totalHabitsToday = allHabits.length;
      final todayCompletionRate = totalHabitsToday > 0
          ? completedToday / totalHabitsToday
          : 0.0;

      // 2. Fetch Weekly Trend
      final startOfThisWeek = today.subtract(Duration(days: now.weekday - 1));
      final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

      final completionsRecentResponse = await supabaseClient
          .from('habit_completions')
          .select('completed_date, habit_id')
          .gte(
            'completed_date',
            startOfLastWeek.toIso8601String().split('T')[0],
          );

      final recentCompletions = completionsRecentResponse as List;
      int thisWeekCount = 0;
      int lastWeekCount = 0;

      for (var comp in recentCompletions) {
        final date = DateTime.parse(comp['completed_date'] as String);
        if (date.isBefore(startOfThisWeek)) {
          lastWeekCount++;
        } else {
          thisWeekCount++;
        }
      }

      double trend = 0.0;
      if (lastWeekCount > 0) {
        trend = (thisWeekCount - lastWeekCount) / lastWeekCount;
      } else if (thisWeekCount > 0) {
        trend = 1.0; // 100% improvement if last week was 0
      }

      // 3. Monthly Summary
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final completionsMonthResponse = await supabaseClient
          .from('habit_completions')
          .select('completed_date, habit_id')
          .gte(
            'completed_date',
            firstDayOfMonth.toIso8601String().split('T')[0],
          );

      final monthCompletions = completionsMonthResponse as List;
      final totalMonthCompletions = monthCompletions.length;

      final completionsByDate = <DateTime, Set<String>>{};
      final completionsByHabit = <String, int>{};

      for (var comp in monthCompletions) {
        final date = DateTime.parse(comp['completed_date'] as String);
        final habitId = comp['habit_id'] as String;

        completionsByDate.update(
          date,
          (val) => val..add(habitId),
          ifAbsent: () => {habitId},
        );
        completionsByHabit.update(habitId, (val) => val + 1, ifAbsent: () => 1);
      }

      int fullCompletionDays = 0;
      if (totalHabitsToday > 0) {
        completionsByDate.forEach((date, habits) {
          if (habits.length >= totalHabitsToday) fullCompletionDays++;
        });
      }

      String mostConsistentHabit = 'None';
      if (completionsByHabit.isNotEmpty) {
        final sortedHabits = completionsByHabit.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final bestHabitId = sortedHabits.first.key;
        final bestHabitName = allHabits.firstWhere(
          (h) => h['id'] == bestHabitId,
          orElse: () => {'name': 'Unknown'},
        )['name'];
        mostConsistentHabit = bestHabitName;
      }

      // 4. Insights Section
      final List<String> insights = [];

      // Best day of week across all habits
      final allCompletionsResponse = await supabaseClient
          .from('habit_completions')
          .select('completed_date');
      final allDates = (allCompletionsResponse as List)
          .map((e) => DateTime.parse(e['completed_date'] as String))
          .toList();
      if (allDates.isNotEmpty) {
        final dayCounts = _calculateCompletionsByDayOfWeek(allDates);
        final bestDay = _calculateBestDayOfWeek(dayCounts);
        insights.add("Your most productive day is $bestDay 📊");
      }

      // Time of day insight
      final allCompletionsWithTime = await supabaseClient
          .from('habit_completions')
          .select('created_at');
      int morningCount = 0;
      int totalCount = 0;
      for (var comp in allCompletionsWithTime as List) {
        final createdAt = DateTime.parse(
          comp['created_at'] as String,
        ).toLocal();
        if (createdAt.hour >= 5 && createdAt.hour < 12) {
          morningCount++;
        }
        totalCount++;
      }
      if (totalCount > 0) {
        final morningRatio = morningCount / totalCount;
        if (morningRatio > 0.6) {
          insights.add(
            "You're ${(morningRatio * 100).toInt()}% more likely to complete habits in the morning ☀️",
          );
        }
      }

      // Best streak insight
      int maxStreak = 0;
      String maxStreakHabit = '';
      final habitsWithStreaks = await supabaseClient
          .from('habits')
          .select('name, longest_streak')
          .order('longest_streak', ascending: false)
          .limit(1);
      if ((habitsWithStreaks as List).isNotEmpty) {
        maxStreak = habitsWithStreaks[0]['longest_streak'] ?? 0;
        maxStreakHabit = habitsWithStreaks[0]['name'];
        if (maxStreak > 0) {
          insights.add("$maxStreakHabit has the longest streak! 🏆");
        }
      }

      // Global streak (consecutive days with at least one completion)
      final sortedUniqueDates =
          allDates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
            ..sort();
      int globalStreak = 0;
      if (sortedUniqueDates.isNotEmpty) {
        int currentGStreak = 0;
        DateTime? prev;
        for (var d in sortedUniqueDates) {
          if (prev == null || d.difference(prev).inDays == 1) {
            currentGStreak++;
          } else {
            currentGStreak = 1;
          }
          prev = d;
          if (currentGStreak > globalStreak) globalStreak = currentGStreak;
        }
        if (globalStreak > 0) {
          insights.add(
            "You've completed habits $globalStreak days in a row! 🔥",
          );
        }
      }

      return Right(
        GlobalStatsEntity(
          completedToday: completedToday,
          totalHabitsToday: totalHabitsToday,
          todayCompletionRate: todayCompletionRate,
          currentWeekCompletions: thisWeekCount,
          lastWeekCompletions: lastWeekCount,
          weeklyTrendPercentage: trend,
          bestStreakThisMonth: 0, // Simplified for now
          mostConsistentHabit: mostConsistentHabit,
          totalMonthCompletions: totalMonthCompletions,
          fullCompletionDays: fullCompletionDays,
          insights: insights,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, int>>> getHeatMapData() async {
    try {
      final response = await supabaseClient
          .from('habit_completions')
          .select('completed_date');

      final Map<DateTime, int> heatMap = {};
      for (var record in response as List) {
        final date = DateTime.parse(record['completed_date'] as String);
        // Normalize to start of day
        final normalizedDate = DateTime(date.year, date.month, date.day);
        heatMap[normalizedDate] = (heatMap[normalizedDate] ?? 0) + 1;
      }
      return Right(heatMap);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    // Normalize dates
    final normalizedDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();
    normalizedDates.sort((a, b) => b.compareTo(a)); // Descending

    int streak = 0;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));

    // Check if distinct dates contains today or yesterday to start streak
    if (normalizedDates.contains(normalizedToday)) {
      streak++;
      var checkDate = yesterday;
      while (normalizedDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (normalizedDates.contains(yesterday)) {
      streak++;
      var checkDate = yesterday.subtract(const Duration(days: 1));
      while (normalizedDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }

  int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final normalizedDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();
    normalizedDates.sort(); // Ascending

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? prevDate;

    for (var date in normalizedDates) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final difference = date.difference(prevDate).inDays;
        if (difference == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }
      if (currentStreak > maxStreak) maxStreak = currentStreak;
      prevDate = date;
    }
    return maxStreak;
  }

  String _calculateBestDayOfWeek(Map<int, int> completionsByDay) {
    if (completionsByDay.isEmpty) return 'None';
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    int bestDay = 1;
    int maxCompletions = -1;
    completionsByDay.forEach((day, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        bestDay = day;
      }
    });
    return days[bestDay - 1];
  }

  double _calculateCurrentWeekProgress(List<DateTime> dates) {
    if (dates.isEmpty) return 0.0;
    final now = DateTime.now();
    // Monday is 1, Sunday is 7
    final currentWeekday = now.weekday;
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: currentWeekday - 1));

    final completionsThisWeek = dates
        .where(
          (d) => d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))),
        )
        .length;
    return completionsThisWeek / currentWeekday;
  }

  Map<DateTime, int> _calculateStreaksOverTime(List<DateTime> dates) {
    if (dates.isEmpty) return {};
    final normalizedDates =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort();

    final Map<DateTime, int> streaks = {};
    int currentStreak = 0;
    DateTime? prevDate;

    for (var date in normalizedDates) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }
      streaks[date] = currentStreak;
      prevDate = date;
    }
    return streaks;
  }

  Map<int, int> _calculateCompletionsPerWeek(List<DateTime> dates) {
    if (dates.isEmpty) return {};
    final now = DateTime.now();
    final Map<int, int> completions = {};

    for (int i = 0; i < 12; i++) {
      final endOfWeek = now.subtract(Duration(days: i * 7));
      final startOfWeek = endOfWeek.subtract(const Duration(days: 7));
      final count = dates
          .where(
            (d) =>
                d.isAfter(startOfWeek) &&
                d.isBefore(endOfWeek.add(const Duration(seconds: 1))),
          )
          .length;
      completions[11 - i] = count;
    }
    return completions;
  }

  Map<int, int> _calculateCompletionsByDayOfWeek(List<DateTime> dates) {
    final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var date in dates) {
      counts[date.weekday] = (counts[date.weekday] ?? 0) + 1;
    }
    return counts;
  }

  List<MilestoneEntity> _calculateMilestones(
    List<DateTime> dates,
    int currentStreak,
    int longestStreak,
  ) {
    final List<Map<String, dynamic>> criteria = [
      {'title': 'First Step', 'icon': '🎯', 'threshold': 1, 'type': 'total'},
      {'title': '7-Day Streak', 'icon': '🔥', 'threshold': 7, 'type': 'streak'},
      {
        'title': '30-Day Streak',
        'icon': '💪',
        'threshold': 30,
        'type': 'streak',
      },
      {
        'title': '100-Day Streak',
        'icon': '🏆',
        'threshold': 100,
        'type': 'streak',
      },
      {
        'title': 'Yearly Legend',
        'icon': '💎',
        'threshold': 365,
        'type': 'streak',
      },
    ];

    return criteria.map((c) {
      final threshold = c['threshold'] as int;
      final isStreak = c['type'] == 'streak';
      final value = isStreak ? longestStreak : dates.length;
      final isAchieved = value >= threshold;

      return MilestoneEntity(
        title: c['title'],
        icon: c['icon'],
        isAchieved: isAchieved,
        progress: (value / threshold).clamp(0.0, 1.0),
        achievedAt: isAchieved
            ? dates.firstWhere((d) => true)
            : null, // Simplification: we'd need exact achievement date logic here for production
      );
    }).toList();
  }
}
