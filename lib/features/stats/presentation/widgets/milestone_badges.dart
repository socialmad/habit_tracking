import 'package:flutter/material.dart';
import 'package:habit_tracker/features/stats/domain/entities/milestone_entity.dart';
import 'package:intl/intl.dart';

class MilestoneBadges extends StatelessWidget {
  final List<MilestoneEntity> milestones;

  const MilestoneBadges({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    final nextMilestone = milestones.where((m) => !m.isAchieved).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextMilestone != null) ...[
          const Text(
            'Next Milestone',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    nextMilestone.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextMilestone.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: nextMilestone.progress,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Achievements',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: milestones.map((milestone) {
            return Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: milestone.isAchieved
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: milestone.isAchieved
                        ? Border.all(color: Colors.amber, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    milestone.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: milestone.isAchieved ? null : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    milestone.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: milestone.isAchieved
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: milestone.isAchieved ? null : Colors.grey,
                    ),
                  ),
                ),
                if (milestone.isAchieved && milestone.achievedAt != null)
                  Text(
                    DateFormat('MMM d, y').format(milestone.achievedAt!),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
