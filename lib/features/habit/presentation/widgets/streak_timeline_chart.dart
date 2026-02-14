import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StreakTimelineChart extends StatelessWidget {
  final List<int> streaksOverTime; // Expecting ordered data points
  final Color color;

  const StreakTimelineChart({
    super.key,
    required this.streaksOverTime,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (streaksOverTime.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No streak data yet')),
      );
    }

    // Generate spots
    List<FlSpot> spots = [];
    for (int i = 0; i < streaksOverTime.length; i++) {
      spots.add(FlSpot(i.toDouble(), streaksOverTime[i].toDouble()));
    }

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (streaksOverTime.length - 1).toDouble(),
          minY: 0,
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
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  return LineTooltipItem(
                    '${touchedSpot.y.toInt()} days',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
