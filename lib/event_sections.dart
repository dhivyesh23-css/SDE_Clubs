// lib/clubs/event_sections.dart
import 'package:flutter/material.dart';

class EventsSection extends StatelessWidget {
  final List<dynamic> events;
  const EventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("🎭 Events",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        ...events.map((e) => EventCard(event: Map<String, dynamic>.from(e))),
      ],
    );
  }
}

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const EventCard({super.key, required this.event});

  Widget _chip(String label, {Color? color, IconData? icon}) {
    return Chip(
      avatar: icon != null ? Icon(icon, size: 16, color: Colors.white) : null,
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color ?? Colors.grey,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List organisers = (event['organisers'] ?? []) as List;
    final List guests = (event['chief_guests'] ?? []) as List;
    final List feedback = (event['audience_feedback'] ?? []) as List;
    final Map<String, dynamic> ops =
        Map<String, dynamic>.from(event['ops'] ?? {});
    final Map<String, dynamic> media =
        Map<String, dynamic>.from(event['media'] ?? {});
    final String date = (event['date'] ?? '').toString();
    final String venue = (event['venue'] ?? '').toString();

    final double rating = (event['audience_rating'] is num)
        ? (event['audience_rating'] as num).toDouble()
        : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(
            children: [
              const Icon(Icons.event, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (event['name'] ?? 'Unnamed Event').toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (date.isNotEmpty || venue.isNotEmpty)
            Text("📅 $date${venue.isNotEmpty ? " | 📍 $venue" : ""}"),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              Text(" Rating: ${rating.toStringAsFixed(2)}"),
              if (event['attendance'] != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.people, size: 18),
                Text(" Attended: ${event['attendance']}"),
              ],
            ],
          ),

          const Divider(height: 24),

          // Organisers
          if (organisers.isNotEmpty) ...[
            const Text("👥 Organisers",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...organisers.map((o) {
              final Map<String, dynamic> bg =
                  Map<String, dynamic>.from(o['background_check'] ?? {});
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text((o['name'] ?? '').toString()),
                subtitle: Text(
                  [
                    (o['role'] ?? '').toString(),
                    if (bg['program'] != null) (bg['program']).toString(),
                    if (bg['joining_year'] != null) "(${bg['joining_year']})",
                  ].where((s) => s.isNotEmpty).join(' | '),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Chief Guests
          if (guests.isNotEmpty) ...[
            const Text("🎤 Chief Guests",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: guests
                  .map((g) => _chip(
                        "${(g['name'] ?? '').toString()} "
                        "(${(g['designation'] ?? 'Guest').toString()})",
                        color: Colors.purple,
                        icon: Icons.person,
                      ))
                  .toList()
                  .cast<Widget>(),
            ),
            const SizedBox(height: 12),
          ],

          // Feedback
          if (feedback.isNotEmpty) ...[
            const Text("📝 Audience Feedback",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...feedback.take(3).map((f) => Text("• ${f.toString()}")),
            if (feedback.length > 3)
              Text("+ ${feedback.length - 3} more...",
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
          ],

          // Media
          if (media.isNotEmpty) ...[
            const Text("📸 Media",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (media['has_poster'] == true)
                  _chip("Poster", color: Colors.teal, icon: Icons.image),
                if (media['has_reel'] == true)
                  _chip("Reel", color: Colors.red, icon: Icons.movie),
                if (media['post_event_recap'] == true)
                  _chip("Recap", color: Colors.indigo, icon: Icons.article),
                if (media['photos_by'] != null &&
                    media['photos_by'].toString().isNotEmpty)
                  _chip("Photos: ${media['photos_by']}",
                      color: Colors.orange, icon: Icons.camera_alt),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Operations
          if (ops.isNotEmpty) ...[
            const Text("💰 Operations",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (ops['budget_estimate_inr'] != null)
              Text("Budget: ₹${ops['budget_estimate_inr']}"),
            if (ops['sponsors'] != null && (ops['sponsors'] as List).isNotEmpty)
              Text("Sponsors: ${(ops['sponsors'] as List).join(', ')}"),
            if (ops['volunteers'] != null)
              Text("Volunteers: ${ops['volunteers']}"),
            if (ops['risk_flags'] != null &&
                (ops['risk_flags'] as List).isNotEmpty)
              Text("Risks: ${(ops['risk_flags'] as List).join(', ')}"),
          ],
        ]),
      ),
    );
  }
}
