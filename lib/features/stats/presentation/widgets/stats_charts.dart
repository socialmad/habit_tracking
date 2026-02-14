import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreakLineChart extends StatelessWidget {
  final Map<DateTime, int> streaksOverTime;
  final Color color;

  const StreakLineChart({
    super.key,
    required this.streaksOverTime,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (streaksOverTime.isEmpty) {
      return const Center(child: Text('Not enough data for streak trend'));
    }

    final sortedDates = streaksOverTime.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), streaksOverTime[sortedDates[i]]!.toDouble()),
      );
    }

    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index % (sortedDates.length ~/ 3 + 1) == 0 &&
                      index < sortedDates.length) {
                    return Text(
                      DateFormat('MMM d').format(sortedDates[index]),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyBarChart extends StatelessWidget {
  final Map<int, int> completionsPerWeek;
  final Color color;

  const WeeklyBarChart({
    super.key,
    required this.completionsPerWeek,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (completionsPerWeek.isEmpty) {
      return const Center(child: Text('No weekly data available'));
    }

    final barGroups = completionsPerWeek.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY:
                  completionsPerWeek.values
                      .fold(0, (max, e) => e > max ? e : max)
                      .toDouble() +
                  1,
              color: color.withAlpha(20),
            ),
          ),
        ],
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1.8,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => color.withAlpha(200),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} completions',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '12w ago',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  if (value == 11) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'This week',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
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
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}

class DayOfWeekPieChart extends StatelessWidget {
  final Map<int, int> completionsByDay;

  const DayOfWeekPieChart({super.key, required this.completionsByDay});

  @override
  Widget build(BuildContext context) {
    if (completionsByDay.values.every((v) => v == 0)) {
      return const Center(child: Text('No completions yet'));
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];

    final sections = completionsByDay.entries.map((entry) {
      final value = entry.value.toDouble();
      return PieChartSectionData(
        value: value,
        title: value > 0 ? days[entry.key - 1] : '',
        color: colors[entry.key - 1],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
