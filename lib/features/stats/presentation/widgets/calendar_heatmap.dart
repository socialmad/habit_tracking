import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HabitCalendarHeatmap extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Map<DateTime, int> datasets;
  final ScrollController? scrollController;
  final Color? baseColor;

  const HabitCalendarHeatmap({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.datasets,
    this.scrollController,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize to midnight for accurate day counting
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final totalDays = normalizedEnd.difference(normalizedStart).inDays + 1;

    final normalizedDatasets = datasets.map(
      (key, value) => MapEntry("${key.year}-${key.month}-${key.day}", value),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const double cellSize = 22.0;
        const double cellSpacing = 6.0;

        List<List<DateTime?>> weeks = [];
        List<DateTime?> currentWeek = List.filled(7, null);

        for (int i = 0; i < totalDays; i++) {
          final date = normalizedStart.add(Duration(days: i));
          // Mon=1, Sun=7 -> Index 0-6
          int dayIndex = date.weekday - 1;
          currentWeek[dayIndex] = date;

          if (dayIndex == 6 || i == totalDays - 1) {
            weeks.add(List.from(currentWeek));
            currentWeek = List.filled(7, null);
          }
        }

        return SizedBox(
          height: (cellSize + cellSpacing) * 7.5,
          child: ListView.separated(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            reverse: false, // History from left to right
            itemCount: weeks.length,
            separatorBuilder: (context, index) => SizedBox(width: cellSpacing),
            itemBuilder: (context, weekIndex) {
              final week = weeks[weekIndex];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (dayIndex) {
                  final date = week[dayIndex];
                  if (date == null) {
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(bottom: cellSpacing),
                    );
                  }

                  final key = "${date.year}-${date.month}-${date.day}";
                  final count = normalizedDatasets[key] ?? 0;
                  final color = _getColorForCount(count, context);

                  return Tooltip(
                    message:
                        '${DateFormat('MMM d').format(date)}: $count completions',
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(bottom: cellSpacing),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }

  Color _getColorForCount(int count, BuildContext context) {
    final color = baseColor ?? Theme.of(context).colorScheme.primary;
    if (count == 0) {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);
    }

    if (count == 1)
      return color.withValues(alpha: 0.3); // Increased opacity slightly
    if (count == 2) return color.withValues(alpha: 0.5);
    if (count == 3) return color.withValues(alpha: 0.75);
    if (count >= 4) return color;

    return color;
  }
}
