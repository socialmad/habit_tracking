import 'package:flutter/material.dart';
import 'package:habit_tracker/features/stats/presentation/widgets/calendar_heatmap.dart';

class ConsistencyMap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final Color? habitColor; // Optional: Pass color if needed for heatmap dots

  const ConsistencyMap({super.key, required this.datasets, this.habitColor});

  @override
  Widget build(BuildContext context) {
    // Calculate last 13 weeks (approx 91 days)
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 91));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
          ), // Edge to edge with page margin
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitCalendarHeatmap(
                startDate: startDate,
                endDate: endDate,
                datasets: datasets,
                baseColor: habitColor,
              ),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildLegendBox(context, 0.1),
                  const SizedBox(width: 2),
                  _buildLegendBox(context, 0.3),
                  const SizedBox(width: 2),
                  _buildLegendBox(context, 0.6),
                  const SizedBox(width: 2),
                  _buildLegendBox(context, 1.0),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(BuildContext context, double opacity) {
    final color = (habitColor ?? Theme.of(context).colorScheme.primary)
        .withValues(alpha: opacity);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
