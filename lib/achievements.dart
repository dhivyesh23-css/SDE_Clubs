import 'package:flutter/material.dart';

class AchievementsSection extends StatelessWidget {
  final List<dynamic> achievements;
  final Map<String, dynamic> leadership;

  const AchievementsSection({
    super.key,
    required this.achievements,
    required this.leadership,
  });

  @override
  Widget build(BuildContext context) {
    // Gather alumni from leadership (president, VPs, core team)
    final alumni = <Map<String, dynamic>>[];

    void collectIfAlumni(Map<String, dynamic>? person) {
      if (person == null) return;
      if (person['is_alumni'] == true) {
        alumni.add(person);
      }
    }

    collectIfAlumni(leadership['president']);
    for (var vp in (leadership['vice_presidents'] ?? [])) {
      collectIfAlumni(vp);
    }
    for (var cm in (leadership['core_team'] ?? [])) {
      collectIfAlumni(cm);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("🏆 Achievements & Alumni Impact",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),

        // Achievements
        if (achievements.isNotEmpty) ...[
          ...achievements.map((a) => Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.orange),
                  title: Text(a['title'] ?? "Achievement"),
                  subtitle: Text(
                      "Year: ${a['year']} | Impact: ${a['impact'] ?? 'N/A'}"),
                ),
              )),
        ],

        const SizedBox(height: 16),

        // Alumni Contributions
        if (alumni.isNotEmpty) ...[
          const Text("🎓 Alumni Contributions",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          ...alumni.map((al) {
            final employment = al['employment'];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(al['name'] ?? "Alumnus"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (employment != null)
                      Text("${employment['role']} @ ${employment['company']}"),
                    if (al['impact_summary'] != null)
                      Text("Impact: ${al['impact_summary']}"),
                    if (al['achievements'] != null)
                      Text("Notable: ${(al['achievements'] as List).join(', ')}"),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }),
        ],
      ],
    );
  }
}
