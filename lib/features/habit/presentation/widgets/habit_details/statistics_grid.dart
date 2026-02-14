import 'package:flutter/material.dart';

class StatisticsGrid extends StatelessWidget {
  final int totalCompletions;
  final double successRate;
  final String bestDay;
  final Color habitColor;

  const StatisticsGrid({
    super.key,
    required this.totalCompletions,
    required this.successRate,
    required this.bestDay,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = habitColor;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildStatCard(
                context,
                icon: Icons.auto_awesome_rounded,
                color: color,
                value: '$totalCompletions',
                label: 'Total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildStatCard(
                context,
                icon: Icons.analytics_rounded,
                color: color,
                value: '${(successRate * 100).toInt()}%',
                label: 'Success Rate',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          icon: Icons.calendar_month_rounded,
          color: color,
          value: bestDay,
          label: 'Most Consistent Day',
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (isWide)
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.grey,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isWide ? 26 : 24,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
