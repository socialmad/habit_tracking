import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_tracker/features/stats/presentation/bloc/stats_bloc.dart';
import 'package:habit_tracker/features/habit/presentation/bloc/habit_bloc.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/stats/presentation/widgets/calendar_heatmap.dart';
import 'package:habit_tracker/core/widgets/shimmer/habit_skeleton.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    context.read<StatsBloc>().add(LoadHeatMap());
    context.read<StatsBloc>().add(LoadGlobalStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
              context.read<HabitBloc>().add(LoadHabits());
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  title: const Text(
                    'Analytics',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  pinned: true,
                  floating: false,
                  expandedHeight: 0,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                if (state is StatsLoading && state is! StatsLoaded)
                  ..._buildLoadingSlivers()
                else if (state is StatsError)
                  SliverFillRemaining(child: Center(child: Text(state.message)))
                else if (state is StatsLoaded)
                  ..._buildLoadedSlivers(context, state)
                else
                  const SliverFillRemaining(
                    child: Center(child: Text('No stats loaded')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildLoadingSlivers() {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildSkeletonCard(height: 160),
            const SizedBox(height: 20),
            _buildSkeletonCard(height: 140),
            const SizedBox(height: 32),
            const HabitSkeleton(isScrollable: false),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _buildLoadedSlivers(BuildContext context, StatsLoaded state) {
    final globalStats = state.globalStats;
    final data = state.heatMapData ?? {};

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            if (globalStats != null) ...[
              _buildGreeting(globalStats),
              const SizedBox(height: 24),
              _buildMainDashboardGrid(globalStats),
              const SizedBox(height: 24),
              _buildWeeklyTrendChart(globalStats),
              const SizedBox(height: 28),
            ],
            if (globalStats != null && globalStats.insights.isNotEmpty) ...[
              _buildSectionTitle('Smart Insights'),
              const SizedBox(height: 12),
              _buildInsightsSection(globalStats.insights),
              const SizedBox(height: 28),
            ],
            _buildSectionTitle('Consistency Map'),
            const SizedBox(height: 12),
            _buildHeatmapCard(data),
            const SizedBox(height: 28),
            _buildSectionTitle('Habit Leaders'),
            const SizedBox(height: 12),
            BlocBuilder<HabitBloc, HabitState>(
              builder: (context, habitState) {
                if (habitState is HabitLoaded) {
                  return _buildAllHabitsSummary(habitState.habits);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildGreeting(dynamic stats) {
    final trend = stats.weeklyTrendPercentage as double;
    final isPositive = trend >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Performance Overview",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isPositive ? Colors.green : Colors.orange).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded,
                size: 16,
                color: isPositive ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                '${trend.abs().toInt()}% ${isPositive ? 'better' : 'consistent'} than last week',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isPositive ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainDashboardGrid(dynamic stats) {
    return Column(
      children: [
        _buildTodayProgressCard(stats),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                "Best Streak",
                "${stats.bestStreakThisMonth}",
                "this month",
                Icons.local_fire_department_rounded,
                const Color(0xFFF97316), // Orange
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                "Monthly",
                "${stats.totalMonthCompletions}",
                "Successes",
                Icons.emoji_events_rounded,
                const Color(0xFF6366F1), // Indigo
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                "Perfect Days",
                "${stats.fullCompletionDays}",
                "this month",
                Icons.star_rounded,
                const Color(0xFFF59E0B), // Amber
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                "Top Habit",
                stats.mostConsistentHabit ?? "None",
                "Most regular",
                Icons.auto_awesome_rounded,
                const Color(0xFF10B981), // Emerald
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 22, color: color.withValues(alpha: 0.6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendChart(dynamic stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Activity Comparison",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This week vs Previous week",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: stats.lastWeekCompletions.toDouble(),
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: stats.currentWeekCompletions.toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        );
                        if (value == 0) {
                          return const Text('Last Week', style: style);
                        }
                        if (value == 1) {
                          return const Text('This Week', style: style);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.surface,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(Map<DateTime, int> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: HabitCalendarHeatmap(
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now(),
        datasets: data,
        baseColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTodayProgressCard(dynamic globalStats) {
    final rate = (globalStats.todayCompletionRate as num).toDouble();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isCompleted = rate >= 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Today's Goal",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${globalStats.completedToday}/${globalStats.totalHabitsToday}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? "Goal Completed! 🎉" : "Keep going!",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 74,
            width: 74,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor.withValues(alpha: 0.08),
                  ),
                ),
                CircularProgressIndicator(
                  value: rate.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(rate * 100).toInt()}%",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.5,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(List<String> insights) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: insights.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.04),
          ),
        ),
        itemBuilder: (context, index) {
          final insight = insights[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    insight,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllHabitsSummary(List<HabitEntity> habits) {
    if (habits.isEmpty) return const SizedBox.shrink();

    final sortedHabits = List<HabitEntity>.from(habits)
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sortedHabits.map((habit) {
          final hColor = Color(int.parse(habit.colorHex, radix: 16));
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        hColor.withValues(alpha: 0.2),
                        hColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    habit.iconAsset,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 14,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${habit.longestStreak}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                        color: hColor,
                      ),
                    ),
                    const Text(
                      'Best',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkeletonCard({double height = 100}) {
    return Shimmer.fromColors(
      baseColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}
