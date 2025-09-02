import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_comparison_page.dart';

class GroupPage extends StatefulWidget {
  final String? initialGroupName;
  const GroupPage({super.key, this.initialGroupName});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  Map<String, List<Map<String, dynamic>>> grouped = {};
  bool isLoading = true;

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
        final category = data['club_type'] ?? "Other";
        tmp.putIfAbsent(category, () => []).add(data);
      }
    }

    if (mounted) {
      setState(() {
        grouped = tmp;
        isLoading = false;
      });

      // Deep-link into a group if requested
      if (widget.initialGroupName != null && grouped.containsKey(widget.initialGroupName)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupComparisonPage(
                groupName: widget.initialGroupName!,
                clubs: grouped[widget.initialGroupName!]!,
              ),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📂 Club Groups")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
              ? const Center(child: Text("No analytics found. Open some clubs first."))
              : ListView(
                  children: grouped.entries.map((entry) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.category),
                        title: Text(entry.key),
                        subtitle: Text("${entry.value.length} clubs"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupComparisonPage(
                                groupName: entry.key,
                                clubs: entry.value,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
