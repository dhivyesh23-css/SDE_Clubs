import 'package:flutter/material.dart';
import 'club_details_page.dart';
import 'rank_page.dart';
import 'group_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏠 Clubs Dashboard")),
      body: ListView(
        children: [
          const ListTile(
            title: Text("Navigation", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.leaderboard, color: Colors.amber),
              title: const Text("Club Rankings"),
              subtitle: const Text("See all 17 clubs ranked by performance"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RankPage()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups, color: Colors.blue),
              title: const Text("Club Groups"),
              subtitle: const Text("Browse clubs by categories/groups"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupPage()),
                );
              },
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text("Standalone Clubs (direct)", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Card(
            child: ListTile(
              title: const Text("Drama Club"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClubDetailsPage(clubName: "Drama Club")),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text("Music Club"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClubDetailsPage(clubName: "Music Club")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
