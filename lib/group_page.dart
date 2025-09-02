import 'package:flutter/material.dart';
import 'group_comparison_page.dart';
import 'club_details_page.dart';

class GroupPage extends StatelessWidget {
  final String? groupName;
  GroupPage({this.groupName});

  final List<String> rankedClubs = ["AI Club", "ML Club", "IoT Club"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName ?? "Group")),
      body: ListView(
        children: rankedClubs.map((club) => ListTile(
          title: Text(club),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => GroupComparisonPage(clubs: rankedClubs)));
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
