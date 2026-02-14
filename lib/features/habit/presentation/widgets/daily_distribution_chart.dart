import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyDistributionChart extends StatelessWidget {
  final Map<int, int> completionsByDay; // Key: 1 (Mon) to 7 (Sun), Value: count

  const DailyDistributionChart({super.key, required this.completionsByDay});

  @override
  Widget build(BuildContext context) {
    if (completionsByDay.isEmpty ||
        completionsByDay.values.every((e) => e == 0)) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Complete habits to see which days are your best!",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Days of week labels
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<Color> colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.yellow.shade700,
    ];

    List<PieChartSectionData> sections = [];
    int total = completionsByDay.values.fold(0, (sum, item) => sum + item);

    for (int i = 1; i <= 7; i++) {
      int count = completionsByDay[i] ?? 0;
      double percentage = total > 0 ? (count / total * 100) : 0;

      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[i - 1],
            value: count.toDouble(),
            title: '${days[i - 1]}\n${percentage.toInt()}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
