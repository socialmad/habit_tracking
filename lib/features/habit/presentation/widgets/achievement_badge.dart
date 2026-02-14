import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon; // Can be IconData or String (emoji)
  final bool isUnlocked;
  final Color color;
  final DateTime? dateEarned;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.color,
    this.dateEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: isUnlocked ? Border.all(color: color, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: icon is IconData
                ? Icon(
                    isUnlocked ? icon : Icons.lock_outline,
                    color: isUnlocked ? color : Colors.grey,
                    size: 30,
                  )
                : Text(
                    isUnlocked ? icon : '🔒',
                    style: TextStyle(
                      fontSize: 30,
                      color: isUnlocked ? null : Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (isUnlocked) ...[
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            if (dateEarned != null)
              Text(
                '${dateEarned!.day}/${dateEarned!.month}/${dateEarned!.year}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ],
      ),
    );
  }
}

class MilestonesSection extends StatelessWidget {
  final List<String>
  milestones; // Just passing unlocked milestone IDs/types for now

  const MilestonesSection({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    // Defines all possible achievements
    final allAchievements = [
      _AchievementDef(
        'First Step',
        'Complete once',
        Icons.flag,
        Colors.blue,
        'first_step',
      ),
      _AchievementDef(
        '7-Day Streak',
        'One week streak',
        Icons.local_fire_department,
        Colors.orange,
        '7_day_streak',
      ),
      _AchievementDef(
        '30-Day Streak',
        'Month streak',
        Icons.star,
        Colors.purple,
        '30_day_streak',
      ),
      _AchievementDef(
        '100-Day Streak',
        'Century',
        Icons.emoji_events,
        Colors.amber,
        '100_day_streak',
      ),
      _AchievementDef(
        'Perfect Week',
        '7 days/week',
        Icons.calendar_today,
        Colors.green,
        'perfect_week',
      ),
      _AchievementDef(
        'Speed Demon',
        'Fast completion',
        Icons.flash_on,
        Colors.red,
        'speed_demon',
      ),
    ];

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: allAchievements.map((def) {
        // Simply checking if list contains the ID for now
        // In real app, milestones might be complex objects
        bool unlocked = milestones.contains(def.id);
        return AchievementBadge(
          title: def.title,
          description: def.description,
          icon: def.icon,
          color: def.color,
          isUnlocked: unlocked,
        );
      }).toList(),
    );
  }
}

class _AchievementDef {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String id;

  _AchievementDef(this.title, this.description, this.icon, this.color, this.id);
}
