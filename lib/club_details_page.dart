import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ClubDetailsPage extends StatefulWidget {
  final String clubName;
  const ClubDetailsPage({super.key, required this.clubName});

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  // Existing state variables
  Map<String, dynamic>? clubData;
  Map<String, dynamic>? whatsappStats;
  bool whatsappTried = false;
  String? whatsappError;

  // New state variables for Instagram data
  bool isLoadingInsta = true;
  Map<String, dynamic>? instaProfile;
  Map<String, dynamic>? instaPostStats;
  String? instaError;

  final Map<String, String> whatsappFolderMap = {
    "Rhythm": "rythm", "Capturesque": "capt", "SNUMUN Society": "snucmun",
    "Potential": "pot", "Coding Club": "cc", "Quiz Club (Cognition)": "cogni",
    "Isai": "isai", "Business Club": "buss", "Handila": "handila", "Lingua": "lit",
  };

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    // Load local club data first
    await loadClubData();

    // Conditionally load WhatsApp data
    if (whatsappFolderMap.containsKey(widget.clubName)) {
      String folder = whatsappFolderMap[widget.clubName]!;
      await loadWhatsappData(folder);
    } else {
      setState(() => whatsappTried = true);
    }

    // NEW: Conditionally load Instagram data
    if (widget.clubName.toLowerCase() == 'coding club') {
      await _fetchInstagramData();
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
      final String path = 'assets/data/whatsapp/$clubFolder/chat.txt';
      final content = await rootBundle.loadString(path);
      final lines = content.split("\n").where((line) => line.trim().isNotEmpty).toList();
      int totalMsgs = lines.length;
      setState(() {
        whatsappStats = {"messages": totalMsgs};
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

  // NEW: Function to fetch and process Instagram data from your backend
  Future<void> _fetchInstagramData() async {
    setState(() => isLoadingInsta = true);
    try {
      // USE THE IP ADDRESS YOU FOUND FROM ipconfig
      final String baseUrl = 'http://localhost:8000';
      const String username = 'snuc_cc';
      final url = Uri.parse('$baseUrl/profile/$username');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['recent_posts'] as List;

        // Calculate stats
        double avgLikes = 0;
        if (posts.isNotEmpty) {
          avgLikes = posts.fold(0.0, (sum, p) => sum + p['likes']) / posts.length;
        }

        double postFrequency = 0; // in days
        if (posts.length > 1) {
          final firstDate = DateTime.parse(posts.first['date_utc']);
          final lastDate = DateTime.parse(posts.last['date_utc']);
          final duration = firstDate.difference(lastDate);
          postFrequency = duration.inDays / (posts.length - 1);
        }

        if (mounted) {
          setState(() {
            instaProfile = data['profile'];
            instaPostStats = {
              "avgLikes": avgLikes,
              "postFrequency": postFrequency,
            };
          });
        }
      } else {
        throw Exception('Failed to load profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => instaError = e.toString());
    } finally {
      if (mounted) setState(() => isLoadingInsta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (clubData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.clubName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(clubData!['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Existing Header and Description widgets)
            Text(clubData!['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(clubData!['category'] ?? "", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(clubData!['description'] ?? "", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            Text("📊 Popularity & Activity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            
            // Existing Popularity score
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text("Popularity Score"),
              subtitle: Text("${clubData!['popularity']}"),
            ),

            // Existing WhatsApp stats
            if (whatsappStats != null)
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text("WhatsApp Messages (30 days)"),
                subtitle: Text("${whatsappStats!['messages']} messages"),
              ),
            
            // NEW: Instagram Stats Section for Coding Club
            if (widget.clubName.toLowerCase() == 'coding club') ...[
              const Divider(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text("Instagram (@snuc_cc)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
              ),
              if (isLoadingInsta)
                const ListTile(leading: CircularProgressIndicator(), title: Text("Loading live stats..."))
              else if (instaError != null)
                ListTile(
                  leading: Icon(Icons.error, color: Colors.red.shade700),
                  title: const Text("Could not load Instagram data"),
                  subtitle: Text(instaError!, style: TextStyle(fontSize: 12)),
                )
              else if (instaProfile != null && instaPostStats != null) ...[
                ListTile(
                  leading: Icon(Icons.people, color: Colors.purple.shade400),
                  title: const Text("Followers"),
                  subtitle: Text("${instaProfile!['followers']}"),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.purple.shade400),
                  title: const Text("Total Posts"),
                  subtitle: Text("${instaProfile!['post_count']}"),
                ),
                ListTile(
                  leading: Icon(Icons.favorite, color: Colors.purple.shade400),
                  title: const Text("Avg. Likes (Recent)"),
                  subtitle: Text(instaPostStats!['avgLikes'].toStringAsFixed(0)),
                ),
                ListTile(
                  leading: Icon(Icons.update, color: Colors.purple.shade400),
                  title: const Text("Post Frequency"),
                  subtitle: Text("Avg. 1 post every ${instaPostStats!['postFrequency'].toStringAsFixed(1)} days"),
                ),
              ]
            ],

            const Divider(),
            
            // ... (Existing Achievements and Events widgets)
            Text("🏆 Achievements", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...((clubData!['achievements'] ?? []) as List).map((a) => ListTile(leading: const Icon(Icons.emoji_events), title: Text(a['title']), subtitle: Text("Year: ${a['year']}"))),
            const Divider(),
            Text("🎭 Events", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...((clubData!['events'] ?? []) as List).map((e) => ListTile(leading: const Icon(Icons.event), title: Text(e['name']), subtitle: Text("Date: ${e['date']} | Venue: ${e['venue']}"))),
          ],
        ),
      ),
    );
  }
}