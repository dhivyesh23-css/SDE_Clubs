import 'package:flutter/material.dart';

class ClubDetailsPage extends StatelessWidget {
  final String clubName;
  ClubDetailsPage({required this.clubName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(clubName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Club: $clubName", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Events: Hackathon, Workshop, Seminar"),
            Text("Head Organiser: John Doe"),
            Text("Chief Guest: Dr. XYZ"),
            SizedBox(height: 20),
            Expanded(child: Center(child: Text("[Graphs & Health Bars Placeholder]", style: TextStyle(color: Colors.grey)))),
          ],
        ),
      ),
    );
  }
}
