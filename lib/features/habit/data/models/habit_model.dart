import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';

class HabitModel extends HabitEntity {
  const HabitModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.description,
    required super.iconAsset,
    required super.colorHex,
    required super.frequency,
    super.categoryId,
    super.reminderTime,
    super.reminderEnabled,
    super.reminderDays,
    required super.createdAt,
    required super.archived,
    super.currentStreak,
    super.longestStreak,
    super.lastCompletedDate,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'] ?? '',
      iconAsset: json['icon_asset'],
      colorHex: json['color_hex'],
      frequency: json['frequency'] == 'daily'
          ? HabitFrequency.daily
          : HabitFrequency.weekly,
      reminderTime: json['reminder_time'] != null
          ? _parseTime(json['reminder_time'])
          : null,
      reminderEnabled: json['reminder_enabled'] ?? false,
      reminderDays: json['reminder_days'] != null
          ? _parseReminderDays(json['reminder_days'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      archived: json['archived'] ?? false,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'])
          : null,
      categoryId: json['category_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'description': description,
      'icon_asset': iconAsset,
      'color_hex': colorHex,
      'frequency': frequency == HabitFrequency.daily ? 'daily' : 'weekly',
      'category_id': categoryId,
      'reminder_time': reminderTime != null ? _formatTime(reminderTime!) : null,
      'reminder_enabled': reminderEnabled,
      'reminder_days': reminderDays,
      'archived': archived,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completed_date': lastCompletedDate
          ?.toIso8601String()
          .split('T')
          .first,
    };
  }

  static DateTime _parseTime(String timeStr) {
    // Supabase returns 'HH:mm:ss'
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0,
    );
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  static List<int>? _parseReminderDays(dynamic days) {
    try {
      if (days == null) return null;

      // Handle List<dynamic> from Supabase
      if (days is List) {
        final result = days
            .map((e) => e is int ? e : int.parse(e.toString()))
            .toList();
        print('📅 Parsed reminder days: $result from $days');
        return result;
      }

      // Handle single value
      if (days is int) {
        print('📅 Parsed single reminder day: [$days]');
        return [days];
      }

      // Handle String format (e.g. "{1,2,3}")
      if (days is String) {
        try {
          final clean = days.replaceAll('{', '').replaceAll('}', '');
          if (clean.trim().isEmpty) return [];
          final result = clean
              .split(',')
              .map((e) => int.parse(e.trim()))
              .toList();
          print('📅 Parsed string reminder days: $result from $days');
          return result;
        } catch (e) {
          print('⚠️ Error parsing string reminder days: $e');
        }
      }

      print('⚠️ Unexpected reminder_days format: $days (${days.runtimeType})');
      return null;
    } catch (e) {
      print('❌ Error parsing reminder_days: $e');
      return null;
    }
  }
}
