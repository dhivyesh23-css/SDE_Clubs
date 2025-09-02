import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'overall_comparison_page.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  List<Map<String, dynamic>> clubs = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith("analytics_"));

    final List<Map<String, dynamic>> loaded = [];
    for (var key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final data = json.decode(jsonStr);
        // compute rankingScore from avg_event_rating + event_success_ratio
        final rating = (data['avg_event_rating'] ?? 0).toDouble();
        final success = (data['event_success_ratio'] ?? 0).toDouble();
        data['rankingScore'] = ((rating * 20) + success) / 2;
        loaded.add(data);
      }
    }

    loaded.sort((a, b) => (b['rankingScore']).compareTo(a['rankingScore']));

    if (mounted) setState(() => clubs = loaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏆 Club Rankings")),
      body: clubs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: clubs.length,
              itemBuilder: (context, index) {
                final club = clubs[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text("${index + 1}")),
                    title: Text(club['club_name']),
                    subtitle: Text("Score: ${club['rankingScore'].toStringAsFixed(1)}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OverallComparisonPage(
                            clubs: clubs,
                            selectedClub: club,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
