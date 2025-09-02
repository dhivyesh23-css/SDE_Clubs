import 'package:flutter/material.dart';
import 'overall_comparison_page.dart';
import 'club_details_page.dart';

class RankPage extends StatelessWidget {
  final List<String> allClubs = [
    "Drama Club", "Music Club", "AI Club", "Sports Club",
    "Robotics Club", "Dance Club", "Coding Club", "Chess Club"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rankings")),
      body: ListView(
        children: allClubs.map((club) => ListTile(
          title: Text(club),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => OverallComparisonPage(clubs: allClubs)));
          },
          trailing: IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailsPage(clubName: club)));
            },
          ),
        )).toList(),
      ),
    );
  }
}
