import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/habit/presentation/bloc/habit_bloc.dart';

class HabitDetailsHeader extends StatelessWidget {
  final HabitEntity habit;

  const HabitDetailsHeader({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 4,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        habit.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Edit Habit',
          onPressed: () => context.push('/edit-habit', extra: habit),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Delete Habit',
          onPressed: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text(
          'This will permanently delete "${habit.name}" and all its history.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<HabitBloc>().add(DeleteHabitEvent(habit.id));
              context.pop();
              context.go('/home');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
