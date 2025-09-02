import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OverallComparisonPage extends StatelessWidget {
  final List<Map<String, dynamic>> clubs;
  final Map<String, dynamic> selectedClub;
  const OverallComparisonPage({
    super.key,
    required this.clubs,
    required this.selectedClub,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📊 Compare: ${selectedClub['club_name']}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barGroups: clubs.map((club) {
              final score = (club['rankingScore'] ?? 0).toDouble();
              return BarChartGroupData(
                x: clubs.indexOf(club),
                barRods: [
                  BarChartRodData(
                    toY: score,
                    color: club['club_name'] == selectedClub['club_name']
                        ? Colors.amber
                        : Colors.blue,
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
