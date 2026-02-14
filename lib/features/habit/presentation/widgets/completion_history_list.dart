import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompletionHistoryList extends StatelessWidget {
  final List<DateTime> completionDates;

  const CompletionHistoryList({super.key, required this.completionDates});

  @override
  Widget build(BuildContext context) {
    if (completionDates.isEmpty) {
      return const Text(
        'No history yet.',
        style: TextStyle(color: Colors.grey),
      );
    }

    // Sort descending
    final sortedDates = List<DateTime>.from(completionDates)
      ..sort((a, b) => b.compareTo(a));
    final displayDates = sortedDates.take(10).toList(); // Show last 10

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayDates.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final date = displayDates[index];
        final isToday = _isSameDay(date, DateTime.now());

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(
            isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(DateFormat('h:mm a').format(date)),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
