import 'package:flutter/material.dart';
import 'club_details_page.dart';
import 'group_page.dart';

class HomePage extends StatelessWidget {
  final List<String> groups = ["Tech Group", "Sports Group"];
  final List<String> standaloneClubs = ["Drama Club", "Music Club"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: ListView(
        children: [
          ListTile(title: Text("Groups", style: TextStyle(fontWeight: FontWeight.bold))),
          ...groups.map((g) => ListTile(
                title: Text(g),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(groupName: g)));
                },
              )),
          ListTile(title: Text("Standalone Clubs", style: TextStyle(fontWeight: FontWeight.bold))),
          ...standaloneClubs.map((c) => ListTile(
                title: Text(c),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailsPage(clubName: c)));
                },
              )),
        ],
      ),
    );
  }
}
