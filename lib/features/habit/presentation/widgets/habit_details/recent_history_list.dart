import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentHistoryList extends StatelessWidget {
  final List<DateTime> completionDates;
  final Color habitColor;

  const RecentHistoryList({
    super.key,
    required this.completionDates,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    // Sort dates descending
    final sortedDates = List<DateTime>.from(completionDates)
      ..sort((a, b) => b.compareTo(a));
    final displayDates = sortedDates.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayDates.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No activity yet',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayDates.length,
            itemBuilder: (context, index) {
              return _buildTimelineItem(
                context,
                displayDates[index],
                isLast: index == displayDates.length - 1,
              );
            },
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    DateTime date, {
    required bool isLast,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (itemDate == today) {
      dateLabel = 'Today';
    } else if (itemDate == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    final timeLabel = DateFormat('h:mm a').format(date);
    final color = habitColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Completed at $timeLabel',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
