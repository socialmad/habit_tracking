import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/habit/presentation/bloc/habit_bloc.dart';
import 'package:habit_tracker/features/categories/presentation/bloc/category_bloc.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  HabitFrequency? _selectedFrequency;
  bool? _selectedArchived;
  bool _onlyActiveStreaks = false;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final state = context.read<HabitBloc>().state;
    if (state is HabitLoaded) {
      _selectedFrequency = state.filterFrequency;
      _selectedArchived = state.filterArchived;
      _onlyActiveStreaks = state.filterOnlyActiveStreaks ?? false;
      _selectedCategoryId = state.filterCategoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Habits',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFrequency = null;
                    _selectedArchived = null;
                    _onlyActiveStreaks = false;
                    _selectedCategoryId = null;
                  });
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Filter
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoriesLoaded) {
                return Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                    ),
                    ...state.categories.map(
                      (cat) => FilterChip(
                        label: Text('${cat.icon} ${cat.name}'),
                        selected: _selectedCategoryId == cat.id,
                        onSelected: (selected) => setState(
                          () => _selectedCategoryId = selected ? cat.id : null,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),

          // Frequency Filter
          const Text(
            'Frequency',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [
              _selectedFrequency == null,
              _selectedFrequency == HabitFrequency.daily,
              _selectedFrequency == HabitFrequency.weekly,
            ],
            onPressed: (index) {
              setState(() {
                if (index == 0) _selectedFrequency = null;
                if (index == 1) _selectedFrequency = HabitFrequency.daily;
                if (index == 2) _selectedFrequency = HabitFrequency.weekly;
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('All'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Daily'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Weekly'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter
          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Active'),
                selected: _selectedArchived == false,
                onSelected: (selected) =>
                    setState(() => _selectedArchived = selected ? false : null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Archived'),
                selected: _selectedArchived == true,
                onSelected: (selected) =>
                    setState(() => _selectedArchived = selected ? true : null),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Streak Filter
          SwitchListTile(
            title: const Text('Only active streaks'),
            value: _onlyActiveStreaks,
            onChanged: (value) => setState(() => _onlyActiveStreaks = value),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<HabitBloc>().add(
                  FilterHabits(
                    categoryId: _selectedCategoryId,
                    frequency: _selectedFrequency,
                    archived: _selectedArchived,
                    onlyActiveStreaks: _onlyActiveStreaks,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
