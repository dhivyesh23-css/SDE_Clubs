import 'package:flutter/material.dart';

class LeadershipSection extends StatelessWidget {
  final Map<String, dynamic> leadership;

  const LeadershipSection({super.key, required this.leadership});

  Widget _buildPersonTile(Map<String, dynamic> person) {
    final bool isAlumni = person['is_alumni'] ?? false;
    final employment = person['employment'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 24,
          child: Icon(Icons.person, size: 28, color: Colors.white),
        ),
        title: Text(
          "${person['name']} (${person['role']})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person['program'] != null) Text("Program: ${person['program']}"),
            if (person['joining_year'] != null)
              Text("Joined: ${person['joining_year']}"),
            if (isAlumni && employment != null) ...[
              const SizedBox(height: 4),
              Text("Alumni @ ${employment['company']}"),
              Text("${employment['role']} (since ${employment['since_year']})"),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final president = leadership['president'] as Map<String, dynamic>?;
    final vicePresidents = (leadership['vice_presidents'] ?? []) as List;
    final coreTeam = (leadership['core_team'] ?? []) as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("👥 Leadership",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),

        if (president != null) ...[
          const Text("President",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          _buildPersonTile(president),
        ],

        if (vicePresidents.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Vice Presidents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ...vicePresidents.map((vp) => _buildPersonTile(vp)),
        ],

        if (coreTeam.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Core Team",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ...coreTeam.map((c) => _buildPersonTile(c)),
        ],
      ],
    );
  }
}
