import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';

import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/stats/presentation/bloc/stats_bloc.dart';
import 'package:habit_tracker/features/tracking/presentation/bloc/tracking_bloc.dart';

// New V2 Widgets
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/header.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/streak_card.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/statistics_grid.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/consistency_map.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/visual_insights_section.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/achievement_grid.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_details/recent_history_list.dart';

class HabitDetailsPage extends StatefulWidget {
  final HabitEntity habit;

  const HabitDetailsPage({super.key, required this.habit});

  @override
  State<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _refreshData();
  }

  void _refreshData() {
    context.read<StatsBloc>().add(LoadHabitStats(widget.habit.id));
    context.read<StatsBloc>().add(LoadHeatMap(habitId: widget.habit.id));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color habitColor = Colors.blue;
    try {
      habitColor = Color(int.parse(widget.habit.colorHex, radix: 16));
    } catch (_) {}

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<TrackingBloc, TrackingState>(
        listener: (context, state) {
          if (state is TrackingLoaded) {
            _refreshData();
          }
        },
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                HabitDetailsHeader(habit: widget.habit),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHabitInfoSection(habitColor),
                      const SizedBox(height: 24),
                      _buildDashboardLabel('At a Glance', habitColor),
                      const SizedBox(height: 16),
                      StreakCards(
                        currentStreak: widget.habit.currentStreak,
                        bestStreak: widget.habit.longestStreak,
                        habitColor: habitColor,
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<StatsBloc, StatsState>(
                        builder: (context, state) {
                          if (state is StatsLoading) {
                            return const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (state is StatsLoaded && state.stats != null) {
                            final s = state.stats!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatisticsGrid(
                                  totalCompletions: s.totalCompletions,
                                  successRate: s.completionRate,
                                  bestDay: s.bestDayOfWeek,
                                  habitColor: habitColor,
                                ),
                                const SizedBox(height: 40),
                                _buildDashboardLabel(
                                  'Consistency Journey',
                                  habitColor,
                                ),
                                const SizedBox(height: 16),
                                ConsistencyMap(
                                  datasets: state.heatMapData ?? {},
                                  habitColor: habitColor,
                                ),
                                const SizedBox(height: 40),
                                _buildDashboardLabel(
                                  'Visual Analytics',
                                  habitColor,
                                ),
                                const SizedBox(height: 16),
                                VisualInsightsSection(
                                  completionsPerWeek: s.completionsPerWeek,
                                  completionsByDay: s.completionsByDayOfWeek,
                                  streakHistory: s.streaksOverTime.values
                                      .toList(),
                                  habitColor: habitColor,
                                ),
                                const SizedBox(height: 40),
                                _buildDashboardLabel('Milestones', habitColor),
                                const SizedBox(height: 16),
                                AchievementGrid(
                                  earnedMilestones: s.milestones,
                                  habitColor: habitColor,
                                ),
                                const SizedBox(height: 40),
                                _buildDashboardLabel(
                                  'Activity Log',
                                  habitColor,
                                ),
                                const SizedBox(height: 16),
                                RecentHistoryList(
                                  completionDates:
                                      state.heatMapData?.keys.toList() ?? [],
                                  habitColor: habitColor,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
            // Confetti Overlay (Non-blocking)
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitInfoSection(Color color) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.habit.iconAsset,
            style: const TextStyle(fontSize: 48),
          ),
        ),
        if (widget.habit.description.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.habit.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDashboardLabel(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
