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
            barGroups: clubs.map((club) {
              final rating = (club['avg_event_rating'] ?? 0) * 20;
              final success = (club['event_success_ratio'] ?? 0).toDouble();
              final score = ((rating + success) / 2).clamp(0, 100);

              return BarChartGroupData(
                x: clubs.indexOf(club),
                barRods: [
                  BarChartRodData(
                    toY: score,
                    color: Colors.primaries[clubs.indexOf(club) % Colors.primaries.length],
                    width: 18,
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(show: false),
          ),
        ),
      ),
    );
  }
}
