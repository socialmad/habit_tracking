import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReminderSettingsWidget extends StatefulWidget {
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;
  final List<int>? reminderDays;
  final ValueChanged<bool> onReminderEnabledChanged;
  final ValueChanged<TimeOfDay?> onReminderTimeChanged;
  final ValueChanged<List<int>?> onReminderDaysChanged;

  const ReminderSettingsWidget({
    super.key,
    required this.reminderEnabled,
    this.reminderTime,
    this.reminderDays,
    required this.onReminderEnabledChanged,
    required this.onReminderTimeChanged,
    required this.onReminderDaysChanged,
  });

  @override
  State<ReminderSettingsWidget> createState() => _ReminderSettingsWidgetState();
}

class _ReminderSettingsWidgetState extends State<ReminderSettingsWidget> {
  static const List<String> _dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const List<String> _fullDayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: widget.reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialBackgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onReminderTimeChanged(picked);
    }
  }

  void _toggleDay(int day) {
    final currentDays = widget.reminderDays ?? [];
    final newDays = List<int>.from(currentDays);

    if (newDays.contains(day)) {
      newDays.remove(day);
    } else {
      newDays.add(day);
    }

    newDays.sort();
    widget.onReminderDaysChanged(newDays.isEmpty ? null : newDays);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDays = widget.reminderDays ?? [];

    // Debug logging
    print('🎛️ ReminderSettingsWidget build:');
    print('   Enabled: ${widget.reminderEnabled}');
    print('   Time: ${widget.reminderTime}');
    print('   Days: ${widget.reminderDays}');
    print('   Selected days: $selectedDays');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.reminderEnabled
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: widget.reminderEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Get notified to complete your habit',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.reminderEnabled,
                onChanged: widget.onReminderEnabledChanged,
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),

          // Time picker (shown when enabled)
          if (widget.reminderEnabled) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Time selection
            Text(
              'Reminder Time',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectTime(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.reminderTime != null
                          ? _formatTime(widget.reminderTime!)
                          : 'Select time',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.reminderTime != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Day selection
            const SizedBox(height: 20),
            Text(
              'Repeat On',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = selectedDays.contains(index);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 6 ? 8 : 0),
                    child: InkWell(
                      onTap: () => _toggleDay(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Tooltip(
                        message: _fullDayNames[index],
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _dayNames[index],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Helper text
            if (selectedDays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Please select at least one day',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
