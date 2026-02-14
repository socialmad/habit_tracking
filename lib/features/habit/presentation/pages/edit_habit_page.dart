import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/habit/presentation/bloc/habit_bloc.dart';
import 'package:habit_tracker/features/categories/presentation/bloc/category_bloc.dart';
import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/reminder_settings_widget.dart';
import 'package:habit_tracker/core/services/notification_service.dart';
import 'package:habit_tracker/injection_container.dart' as di;

class EditHabitPage extends StatefulWidget {
  final HabitEntity habit;
  const EditHabitPage({super.key, required this.habit});

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  late String _selectedIcon;
  late Color _selectedColor;
  late HabitFrequency _frequency;
  String? _selectedCategoryId;

  // Reminder settings
  late bool _reminderEnabled;
  TimeOfDay? _reminderTime;
  List<int>? _reminderDays;

  final List<String> _animalIcons = [
    '🦁',
    '🐯',
    '🐘',
    '🦒',
    '🦓',
    '🦍',
    '🦏',
    '🐆',
    '🐊',
    '🐫',
  ];

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.name);
    _descriptionController = TextEditingController(
      text: widget.habit.description,
    );
    _selectedIcon = widget.habit.iconAsset;
    _frequency = widget.habit.frequency;

    try {
      _selectedColor = Color(int.parse(widget.habit.colorHex, radix: 16));
    } catch (_) {
      _selectedColor = Colors.blue;
    }
    _selectedCategoryId = widget.habit.categoryId;

    // Initialize reminder settings
    _reminderEnabled = widget.habit.reminderEnabled;
    if (widget.habit.reminderTime != null) {
      _reminderTime = TimeOfDay(
        hour: widget.habit.reminderTime!.hour,
        minute: widget.habit.reminderTime!.minute,
      );
    }
    _reminderDays = widget.habit.reminderDays;

    // Debug logging
    print('🔔 Edit Habit - Reminder Settings Loaded:');
    print('  Enabled: $_reminderEnabled');
    print('  Time: $_reminderTime');
    print('  Days: $_reminderDays');
    print(
      '  From Habit: ${widget.habit.reminderTime}, ${widget.habit.reminderDays}',
    );

    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSavePressed() async {
    if (_formKey.currentState!.validate()) {
      // Validate reminder settings if enabled
      if (_reminderEnabled) {
        if (_reminderTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a reminder time'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        if (_reminderDays == null || _reminderDays!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one day for reminders'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Convert TimeOfDay to DateTime for storage
      DateTime? reminderDateTime;
      if (_reminderTime != null) {
        reminderDateTime = DateTime(
          2000,
          1,
          1,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
      }

      final updatedHabit = HabitEntity(
        id: widget.habit.id,
        userId: widget.habit.userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        iconAsset: _selectedIcon,
        colorHex: _selectedColor.value.toRadixString(16),
        frequency: _frequency,
        categoryId: _selectedCategoryId,
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderDateTime,
        reminderDays: _reminderDays,
        createdAt: widget.habit.createdAt,
        archived: widget.habit.archived,
        currentStreak: widget.habit.currentStreak,
        longestStreak: widget.habit.longestStreak,
        lastCompletedDate: widget.habit.lastCompletedDate,
      );

      context.read<HabitBloc>().add(UpdateHabitEvent(updatedHabit));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitBloc, HabitState>(
      listener: (context, state) {
        if (state is HabitLoaded) {
          if (!mounted) return;
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit updated successfully! ✨')),
          );
        } else if (state is HabitError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is HabitLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Habit'),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _onSavePressed,
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Icon',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _animalIcons.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final icon = _animalIcons[index];
                          final isSelected = _selectedIcon == icon;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _selectedColor.withAlpha(40)
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? _selectedColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Color',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colors.length,
                        itemBuilder: (context, index) {
                          final color = _colors[index];
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Habit Name',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter a name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.done,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, catState) {
                        List<CategoryEntity> categories = [];
                        String? safeSelectedCategoryId =
                            null; // Default to null

                        if (catState is CategoriesLoaded) {
                          categories = catState.categories;

                          // Only use the selected category if it exists in the list
                          if (_selectedCategoryId != null &&
                              categories.any(
                                (cat) => cat.id == _selectedCategoryId,
                              )) {
                            safeSelectedCategoryId = _selectedCategoryId;
                          }
                        }

                        return DropdownButtonFormField<String?>(
                          value: safeSelectedCategoryId,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          hint: const Text('No Category'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No Category'),
                            ),
                            ...categories.map(
                              (cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Row(
                                  children: [
                                    Text(cat.icon),
                                    const SizedBox(width: 8),
                                    Text(cat.name),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedCategoryId = value),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Frequency',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<HabitFrequency>(
                      segments: const [
                        ButtonSegment(
                          value: HabitFrequency.daily,
                          label: Text('Daily'),
                        ),
                        ButtonSegment(
                          value: HabitFrequency.weekly,
                          label: Text('Weekly'),
                        ),
                      ],
                      selected: {_frequency},
                      onSelectionChanged: (Set<HabitFrequency> newSelection) {
                        setState(() => _frequency = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Reminder Settings
                    ReminderSettingsWidget(
                      reminderEnabled: _reminderEnabled,
                      reminderTime: _reminderTime,
                      reminderDays: _reminderDays,
                      onReminderEnabledChanged: (value) async {
                        if (value) {
                          final granted = await di
                              .sl<NotificationService>()
                              .requestPermissions();
                          if (granted) {
                            setState(() => _reminderEnabled = true);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Permission denied. Please enable notifications in settings.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            setState(() => _reminderEnabled = false);
                          }
                        } else {
                          setState(() => _reminderEnabled = false);
                        }
                      },
                      onReminderTimeChanged: (value) {
                        setState(() => _reminderTime = value);
                      },
                      onReminderDaysChanged: (value) {
                        setState(() => _reminderDays = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
