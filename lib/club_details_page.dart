import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'leadership.dart';
import 'growthchart.dart';
import 'event_sections.dart';
import 'achievements.dart';
import 'analytics.dart';

class ClubDetailsPage extends StatefulWidget {
  final String clubName;
  const ClubDetailsPage({super.key, required this.clubName});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  Map<String, dynamic>? clubData;
  Map<String, dynamic>? whatsappStats;
  bool whatsappTried = false;
  String? whatsappError;

  bool isLoadingInsta = true;
  Map<String, dynamic>? instaProfile;
  Map<String, dynamic>? instaPostStats;
  String? instaError;

  final Map<String, String> whatsappFolderMap = {
    "Rhythm": "rythm", "Capturesque": "capt", "SNUMUN Society": "snucmun",
    "Potential": "pot", "Coding Club": "cc", "Quiz Club (Cognition)": "cogni",
    "Isai": "isai", "Business Club": "buss", "Handila": "handila", "Lingua": "lit",
  };

  final Map<String, Map<String, String>> socialMediaHandles = {
    "Coding Club": {"instagram": "snuc_cc"},
    "Business Club": {"instagram": "snuc_business"},
  };

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    await loadClubData();
    if (whatsappFolderMap.containsKey(widget.clubName)) {
      String folder = whatsappFolderMap[widget.clubName]!;
      await loadWhatsappData(folder);
    } else {
      setState(() => whatsappTried = true);
    }

    if (socialMediaHandles.containsKey(widget.clubName)) {
      final handles = socialMediaHandles[widget.clubName]!;
      if (handles.containsKey('instagram')) {
        await _fetchInstagramData(handles['instagram']!);
      } else {
        setState(() => isLoadingInsta = false);
      }
    } else {
      setState(() => isLoadingInsta = false);
    }

    // Save derived analytics to SharedPreferences
    if (clubData != null) {
      await _saveAnalyticsToPrefs();
    }
  }

  Future<void> loadClubData() async {
    final String response =
        await rootBundle.loadString('assets/data/snuc_clubs_massive_mock_dataset.json');
    final data = json.decode(response);
    final clubs = data['clubs'] as List;
    final selectedClub = clubs.firstWhere(
        (club) => club['name'].toLowerCase() == widget.clubName.toLowerCase(),
        orElse: () => null);
    if (mounted) setState(() => clubData = selectedClub);
  }

  Future<void> loadWhatsappData(String clubFolder) async {
    try {
      final String path = '/data/whatsapp/$clubFolder/chat.txt';
      final content = await rootBundle.loadString(path);
      final lines = content.split("\n").where((line) => line.trim().isNotEmpty).toList();
      int totalMsgs = lines.length;

      double activityScore = (totalMsgs / 1500.0) * 100.0;

      setState(() {
        whatsappStats = {
          "messages": totalMsgs,
          "activityScore": activityScore.clamp(0.0, 100.0)
        };
        whatsappTried = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          whatsappError = e.toString();
          whatsappTried = true;
        });
      }
    }
  }

  Future<void> _fetchInstagramData(String username) async {
    setState(() => isLoadingInsta = true);
    try {
      const String baseUrl = 'http://localhost:8000';
      final url = Uri.parse('$baseUrl/profile/$username');
      final response = await http.get(url).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['recent_posts'] as List?;

        double avgLikes = 0;
        if (posts != null && posts.isNotEmpty) {
          avgLikes = posts.fold(0.0, (sum, p) => sum + (p['likes'] ?? 0)) / posts.length;
        }

        double postFrequency = 0;
        if (posts != null && posts.length > 1) {
          try {
            final firstDate = DateTime.parse(posts.first['date_utc']);
            final lastDate = DateTime.parse(posts.last['date_utc']);
            final duration = firstDate.difference(lastDate);
            if (duration.inDays > 0 && posts.length > 1) {
              postFrequency = duration.inDays / (posts.length - 1);
            }
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            instaProfile = data['profile'];
            instaPostStats = {"avgLikes": avgLikes, "postFrequency": postFrequency};
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => instaError = e.toString());
    } finally {
      if (mounted) setState(() => isLoadingInsta = false);
    }
  }

  Future<void> _saveAnalyticsToPrefs() async {
    if (clubData == null) return;
    final prefs = await SharedPreferences.getInstance();
    final events = (clubData!['events'] ?? []) as List;

    double avgRating = 0;
    if (events.isNotEmpty) {
      final ratings = events.map((e) => (e['audience_rating'] ?? 0).toDouble()).toList();
      avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    }

    final successRatio = events.isEmpty
        ? 0
        : (events.where((e) => (e['audience_rating'] ?? 0) >= 4.0).length / events.length * 100);

    String growthTrend = "Stagnant";
    if (events.length > 1) {
      final first = events.first['club_members_before'] ?? 0;
      final last = events.last['club_members_after'] ?? first;
      if (last > first) growthTrend = "Positive";
      else if (last < first) growthTrend = "Decline";
    }

    final analytics = {
      "club_name": clubData!['name'],
      "club_type": clubData!['category'],
      "avg_event_rating": avgRating,
      "event_success_ratio": successRatio,
      "growth_trend": growthTrend,
    };

    await prefs.setString("analytics_${clubData!['name']}", json.encode(analytics));
  }

  // -------- Widgets --------

  Widget _buildSocialMediaSection() {
    if (!socialMediaHandles.containsKey(widget.clubName)) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text("📱 Social Media Presence",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        _buildInstagramSection(),
      ],
    );
  }

  Widget _buildInstagramSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.camera_alt, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text("Instagram (@${socialMediaHandles[widget.clubName]!['instagram']})",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
            ]),
            const SizedBox(height: 12),
            if (isLoadingInsta)
              const CircularProgressIndicator(strokeWidth: 2)
            else if (instaProfile != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Followers", "${instaProfile!['followers'] ?? 0}"),
                  _buildStatColumn("Posts", "${instaProfile!['post_count'] ?? 0}"),
                  _buildStatColumn("Following", "${instaProfile!['following'] ?? 0}"),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) => Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (clubData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.clubName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    double overallPopularity = (clubData!['popularity'] as num).toDouble();
    if (whatsappStats != null) {
      final staticScore = (clubData!['popularity'] as num).toDouble();
      final activityScore = (whatsappStats!['activityScore'] as double);
      overallPopularity = (staticScore * 0.4) + (activityScore * 0.6);
    }

    return Scaffold(
      appBar: AppBar(title: Text(clubData!['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(clubData!['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(clubData!['category'] ?? "",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          Text(clubData!['description'] ?? "", style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 24),
          const Text("📊 Popularity & Activity",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text("Overall Popularity Score"),
              subtitle: Text("${overallPopularity.toStringAsFixed(0)}/100"),
            ),
          ),

          if (whatsappStats != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text("WhatsApp Activity"),
                subtitle: Text("${whatsappStats!['messages']} messages (30 days)"),
              ),
            ),

          _buildSocialMediaSection(),

          // Growth chart
          if ((clubData!['events'] ?? []).isNotEmpty)
            GrowthChart(events: clubData!['events']),

          // Achievements & Alumni
          AchievementsSection(
            achievements: (clubData!['achievements'] ?? []) as List,
            leadership: clubData!['leadership'] ?? {},
          ),

          // Events full cards
          EventsSection(events: (clubData!['events'] ?? []) as List),

          // Analytics grid
          AnalyticsSection(events: (clubData!['events'] ?? []) as List, clubData: clubData!),
        ]),
      ),
    );
  }
}

