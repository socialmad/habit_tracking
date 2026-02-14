import 'package:equatable/equatable.dart';

class MilestoneEntity extends Equatable {
  final String title;
  final String icon;
  final DateTime? achievedAt;
  final bool isAchieved;
  final double progress; // 0.0 to 1.0

  const MilestoneEntity({
    required this.title,
    required this.icon,
    this.achievedAt,
    required this.isAchieved,
    required this.progress,
  });

  @override
  List<Object?> get props => [title, icon, achievedAt, isAchieved, progress];
}
