import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyPerformanceChart extends StatelessWidget {
  final Map<int, int>
  completionsPerWeek; // Key: week index (0 = this week), Value: count
  final Color color;

  const WeeklyPerformanceChart({
    super.key,
    required this.completionsPerWeek,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (completionsPerWeek.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No data available")),
      );
    }

    // We want to show maybe last 12 weeks. keys might be week indices relative to something or just 0,1,2..
    // Assuming 0 is current week, 1 is previous, etc. and we want to show reversed on chart (oldest on left)

    // Let's assume input is: 0 (current) -> count, 1 (last week) -> count...
    // We want to display chart left-to-right: 11 weeks ago ... current week

    List<BarChartGroupData> barGroups = [];
    int maxWeeks = 12;

    for (int i = maxWeeks - 1; i >= 0; i--) {
      int count = completionsPerWeek[i] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: maxWeeks - 1 - i, // 0 to 11
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: i == 0
                  ? color
                  : color.withValues(alpha: 0.5), // Highlight current week
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 7, // Max 7 days
                color: const Color(0xFFF3F4F6),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 7,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} times',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index == 11) {
                    return const Text(
                      'Now',
                      style: TextStyle(fontSize: 10),
                    ); // Current week
                  }
                  if (index == 0) {
                    return const Text(
                      '12w',
                      style: TextStyle(fontSize: 10),
                    ); // 12 weeks ago
                  }
                  if (index == 6) {
                    return const Text('6w', style: TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
