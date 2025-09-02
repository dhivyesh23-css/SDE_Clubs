import 'package:flutter/material.dart';

class AnalyticsSection extends StatelessWidget {
  final List<dynamic> events;
  final Map<String, dynamic> clubData;

  const AnalyticsSection({
    super.key,
    required this.events,
    required this.clubData,
  });

  double _calcAvgEventRating() {
    if (events.isEmpty) return 0;
    final ratings = events
        .map((e) => (e['audience_rating'] ?? 0).toDouble())
        .where((r) => r > 0)
        .toList();
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  double _calcEventSuccessRatio() {
    if (events.isEmpty) return 0;
    final successEvents = events
        .where((e) => (e['audience_rating'] ?? 0) >= 4.0)
        .length;
    return successEvents / events.length * 100;
  }

  String _calcGrowthTrend() {
    if (events.length < 2) return "Stagnant";
    final first = events.first['club_members_before'] ?? 0;
    final last = events.last['club_members_after'] ?? first;
    if (last > first) return "Positive";
    if (last < first) return "Decline";
    return "Stagnant";
  }

  double _calcAudienceSentiment() {
    if (events.isEmpty) return 0;
    int pos = 0, neg = 0;
    for (var e in events) {
      final feedback = (e['audience_feedback'] ?? []) as List;
      for (var f in feedback) {
        if (f.toString().toLowerCase().contains("love") ||
            f.toString().toLowerCase().contains("great") ||
            f.toString().toLowerCase().contains("fantastic")) {
          pos++;
        } else {
          neg++;
        }
      }
    }
    if (pos + neg == 0) return 0;
    return pos / (pos + neg) * 100;
  }

  double _calcNetworkInfluence() {
    int count = 0;
    for (var e in events) {
      final guests = (e['chief_guests'] ?? []) as List;
      count += guests.length;
    }
    return count.toDouble();
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = _calcAvgEventRating();
    final successRatio = _calcEventSuccessRatio();
    final growthTrend = _calcGrowthTrend();
    final sentiment = _calcAudienceSentiment();
    final influence = _calcNetworkInfluence();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("📊 Club Analytics",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMetricCard(
                "Avg. Event Rating", avgRating.toStringAsFixed(2),
                Icons.star, Colors.amber),
            _buildMetricCard(
                "Event Success Ratio", "${successRatio.toStringAsFixed(0)}%",
                Icons.check_circle, Colors.green),
            _buildMetricCard(
                "Growth Trend", growthTrend,
                Icons.trending_up,
                growthTrend == "Positive"
                    ? Colors.green
                    : growthTrend == "Decline"
                        ? Colors.red
                        : Colors.grey),
            _buildMetricCard(
                "Audience Sentiment", "${sentiment.toStringAsFixed(0)}%",
                Icons.chat_bubble, Colors.blue),
            _buildMetricCard(
                "Network Influence", influence.toStringAsFixed(0),
                Icons.people, Colors.deepPurple),
          ],
        ),
      ],
    );
  }
}
