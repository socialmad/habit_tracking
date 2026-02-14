import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/tracking/presentation/bloc/tracking_bloc.dart';

class HabitHeroSection extends StatelessWidget {
  final HabitEntity habit;
  final ConfettiController confettiController;
  final bool isCompletedToday;

  const HabitHeroSection({
    super.key,
    required this.habit,
    required this.confettiController,
    required this.isCompletedToday,
  });

  @override
  Widget build(BuildContext context) {
    Color habitColor = Colors.blue;
    try {
      habitColor = Color(int.parse(habit.colorHex, radix: 16));
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: habitColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: habitColor.withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Floating Achievement Icon
            Hero(
              tag: 'habit_icon_${habit.id}',
              child: Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      habitColor.withValues(alpha: 0.2),
                      habitColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isCompletedToday)
                      BoxShadow(
                        color: habitColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Text(
                  habit.iconAsset,
                  style: const TextStyle(
                    fontSize: 44,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Habit Information
            Hero(
              tag: 'habit_name_${habit.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  habit.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),

            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                habit.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Action Center
            _buildActionButton(context, habitColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Color color) {
    if (isCompletedToday) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Goal achieved today',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 56,
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.heavyImpact();
            confettiController.play();
            context.read<TrackingBloc>().add(ToggleHabitCompletion(habit.id));
          },
          icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          label: const Text('Complete Today'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }
  }
}
