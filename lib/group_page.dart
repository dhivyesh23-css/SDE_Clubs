import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_comparison_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  Map<String, List<Map<String, dynamic>>> grouped = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith("analytics_"));

    final Map<String, List<Map<String, dynamic>>> tmp = {};
    for (var key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final data = json.decode(jsonStr);

        final clubName = (data['club_name'] ?? "").toString().toLowerCase();
        final clubType = (data['club_type'] ?? "").toString().toLowerCase();

        // 🔥 Super lenient grouping
        String group = "General";

        if (clubName.contains("code") ||
            clubName.contains("quiz") ||
            clubName.contains("math") ||
            clubType.contains("tech") ||
            clubType.contains("academic")) {
          group = "Tech & Academics";
        } else if (clubName.contains("music") ||
            clubName.contains("isai") ||
            clubName.contains("rhythm") ||
            clubName.contains("dance") ||
            clubName.contains("art") ||
            clubType.contains("cultural") ||
            clubType.contains("arts")) {
          group = "Cultural & Arts";
        } else if (clubName.contains("mun") ||
            clubName.contains("business") ||
            clubName.contains("potential") ||
            clubName.contains("lingua") ||
            clubName.contains("leadership") ||
            clubType.contains("debate") ||
            clubType.contains("professional")) {
          group = "Leadership & Professional";
        } else if (clubName.contains("sport") ||
            clubName.contains("games") ||
            clubType.contains("fitness")) {
          group = "Sports & Games";
        } else {
          // default bias: shove everything else into Cultural & Arts
          group = "Cultural & Arts";
        }

        tmp.putIfAbsent(group, () => []).add(data);
      }
    }

    if (mounted) setState(() => grouped = tmp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏷️ Loose Groups")),
      body: grouped.isEmpty
          ? const Center(child: Text("No analytics found. Open some clubs first."))
          : ListView(
              children: grouped.entries.map((entry) {
                final groupName = entry.key;
                final clubs = entry.value;

                return ListTile(
                  title: Text("$groupName (${clubs.length})"),
                  subtitle: Text(clubs.map((c) => c['club_name']).join(", ")),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupComparisonPage(
                          groupName: groupName,
                          clubs: clubs,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}
