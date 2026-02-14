import 'package:flutter/material.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/weekly_performance_chart.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/daily_distribution_chart.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/streak_timeline_chart.dart';

class VisualInsightsSection extends StatelessWidget {
  final Map<int, int> completionsPerWeek;
  final Map<int, int> completionsByDay;
  final List<int> streakHistory;
  final Color habitColor;

  const VisualInsightsSection({
    super.key,
    required this.completionsPerWeek,
    required this.completionsByDay,
    required this.streakHistory,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartCard(
          context,
          'Streak Trend',
          'Growth over time',
          StreakTimelineChart(
            streaksOverTime: streakHistory.isEmpty ? [0, 0, 0] : streakHistory,
            color: habitColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          context,
          'Weekly Performance',
          'Completions per week',
          WeeklyPerformanceChart(
            completionsPerWeek: completionsPerWeek,
            color: habitColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          context,
          'Best Days',
          "Daily consistency pattern",
          DailyDistributionChart(completionsByDay: completionsByDay),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    String title,
    String subtitle,
    Widget chart,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: habitColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }
}
