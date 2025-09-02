import 'package:flutter/material.dart';

class OverallComparisonPage extends StatelessWidget {
  final List<String> clubs;
  OverallComparisonPage({required this.clubs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Overall Comparison")),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text("Line Graph of All Clubs", style: TextStyle(fontSize: 18)),
            Expanded(child: Center(child: Text("[Line Graph Placeholder]"))),
            Text("Vertical Bars of All Clubs", style: TextStyle(fontSize: 18)),
            Expanded(child: Center(child: Text("[Vertical Bars Placeholder]"))),
          ],
        ),
      ),
    );
  }
}
