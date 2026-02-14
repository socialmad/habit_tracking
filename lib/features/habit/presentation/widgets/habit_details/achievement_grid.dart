import 'package:flutter/material.dart';
import 'package:habit_tracker/features/stats/domain/entities/milestone_entity.dart';

class AchievementGrid extends StatelessWidget {
  final List<MilestoneEntity> earnedMilestones;
  final Color habitColor;

  const AchievementGrid({
    super.key,
    required this.earnedMilestones,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    if (earnedMilestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: earnedMilestones.length,
            itemBuilder: (context, index) {
              final milestone = earnedMilestones[index];
              return _buildAchievementItem(context, milestone);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
    BuildContext context,
    MilestoneEntity milestone,
  ) {
    final isEarned = milestone.isAchieved;
    final displayColor = isEarned ? habitColor : Colors.grey;

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                milestone.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: isEarned ? null : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            milestone.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: isEarned ? 1.0 : 0.6),
            ),
          ),
          if (!isEarned) ...[
            const SizedBox(height: 2),
            Text(
              '${(milestone.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
