import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'club_details_page.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> allClubs = [];
  String query = "";

  @override
  void initState() {
    super.initState();
    loadClubs();
  }

  Future<void> loadClubs() async {
    final String response =
        await rootBundle.loadString('assets/data/snuc_clubs_massive_mock_dataset.json');
    final data = json.decode(response);
    setState(() {
      allClubs = data['clubs']; // adjust if your JSON structure is different
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = allClubs
        .where((club) =>
            club['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Search")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search clubs...",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => query = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final club = results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade100,
                    child: Icon(Icons.group, color: Colors.blueGrey.shade700),
                  ),
                  title: Text(club['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClubDetailsPage(clubName: club['name']),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
