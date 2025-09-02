import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GroupComparisonPage extends StatelessWidget {
  final String groupName;
  final List<Map<String, dynamic>> clubs;
  const GroupComparisonPage({
    super.key,
    required this.groupName,
    required this.clubs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📈 $groupName Comparison")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barGroups: clubs.asMap().entries.map((entry) {
              final index = entry.key;
              final club = entry.value;

              final rating = (club['avg_event_rating'] ?? 0) * 20;
              final success = (club['event_success_ratio'] ?? 0).toDouble();
              final score = ((rating + success) / 2).clamp(0, 100);

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: score,
                    color: Colors.primaries[index % Colors.primaries.length],
                    width: 18,
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int idx = value.toInt();
                    if (idx < 0 || idx >= clubs.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        clubs[idx]['club_name'] ?? "Club",
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                  reservedSize: 60, // space for labels
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        ),
      ),
    );
  }
}
