import 'package:flutter/material.dart';

class GroupComparisonPage extends StatelessWidget {
  final List<String> clubs;
  GroupComparisonPage({required this.clubs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Group Comparison")),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text("Line Graph Comparing Clubs", style: TextStyle(fontSize: 18)),
            Expanded(child: Center(child: Text("[Line Graph Placeholder]"))),
            Text("Vertical Bars Comparison", style: TextStyle(fontSize: 18)),
            Expanded(child: Center(child: Text("[Vertical Bars Placeholder]"))),
          ],
        ),
      ),
    );
  }
}
