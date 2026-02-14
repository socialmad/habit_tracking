import 'package:equatable/equatable.dart';

enum HabitFrequency { daily, weekly }

enum HabitSortOption {
  recentlyAdded,
  nameAZ,
  currentStreak,
  completionRate,
  category,
  custom,
}

class HabitEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String iconAsset;
  final String colorHex;
  final HabitFrequency frequency;
  final String? categoryId;
  final DateTime? reminderTime;
  final bool reminderEnabled;
  final List<int>? reminderDays; // 0-6 for Sunday-Saturday
  final DateTime createdAt;
  final bool archived;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  const HabitEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.colorHex,
    required this.frequency,
    this.categoryId,
    this.reminderTime,
    this.reminderEnabled = false,
    this.reminderDays,
    required this.createdAt,
    required this.archived,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    iconAsset,
    colorHex,
    frequency,
    categoryId,
    reminderTime,
    reminderEnabled,
    reminderDays,
    createdAt,
    archived,
    currentStreak,
    longestStreak,
    lastCompletedDate,
  ];
}
