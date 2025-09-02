import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Helper class for type-safety to prevent null errors.
class _MemberDataPoint {
  final DateTime date;
  final int count;

  _MemberDataPoint({required this.date, required this.count});
}

class GrowthChart extends StatelessWidget {
  final List<dynamic> events;

  const GrowthChart({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.length < 2) {
      return const SizedBox.shrink();
    }

    // 1. Map raw data to a strongly-typed list. This is the core fix.
    final dataPoints = events.map((e) {
      final date = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
      final membersAfter = (e['club_members_after'] ?? 0) as int;
      return _MemberDataPoint(date: date, count: membersAfter);
    }).toList()
      // 2. Sort the typed list. The compiler now knows `a.date` is a DateTime.
      ..sort((a, b) => a.date.compareTo(b.date));

    // 3. Map the typed list to FlSpot. No more unsafe access.
    final spots = dataPoints.map((dp) {
      return FlSpot(
        dp.date.millisecondsSinceEpoch.toDouble(),
        dp.count.toDouble(),
      );
    }).toList();

    if (spots.isEmpty) {
        return const SizedBox.shrink();
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("📈 Member Growth",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY - 5,
              maxY: maxY + 5,
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxX - minX) / 4, // Adjust interval for clarity
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('MMM \'yy').format(date),
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  color: Colors.blue,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ],
    );
  }
}