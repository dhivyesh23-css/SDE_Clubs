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

  // Instagram state variables
  bool isLoadingInsta = true;
  Map<String, dynamic>? instaProfile;
  Map<String, dynamic>? instaPostStats;
  String? instaError;

  // WhatsApp folder mapping (unchanged)
  final Map<String, String> whatsappFolderMap = {
    "Rhythm": "rythm", "Capturesque": "capt", "SNUMUN Society": "snucmun",
    "Potential": "pot", "Coding Club": "cc", "Quiz Club (Cognition)": "cogni",
    "Isai": "isai", "Business Club": "buss", "Handila": "handila", "Lingua": "lit",
  };

  // Social media handles mapping
  final Map<String, Map<String, String>> socialMediaHandles = {
    "Coding Club": {
      "instagram": "snuc_cc",
      "linkedin": "snuc-coding-club" // Kept for structure, but not used
    },
    // Add more clubs and their handles here
    "Business Club": {
      "instagram": "snuc_business",
      "linkedin": "snu-business-club" // Kept for structure, but not used
    },
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

    // Load social media data if handles exist
    if (socialMediaHandles.containsKey(widget.clubName)) {
      final handles = socialMediaHandles[widget.clubName]!;
      
      // Load Instagram data
      if (handles.containsKey('instagram')) {
        await _fetchInstagramData(handles['instagram']!);
      } else {
        setState(() => isLoadingInsta = false);
      }
      
    } else {
      setState(() {
        isLoadingInsta = false;
      });
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

      // UPDATED SCALE: 50 msgs/day (1500/month) is the new 100% mark for activity.
      double activityScore = (totalMsgs / 1500.0) * 100.0;

      setState(() {
        whatsappStats = {
          "messages": totalMsgs,
          // Clamp the score to a maximum of 100
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
      // For mobile testing, replace 'localhost' with your computer's IP address
      const String baseUrl = 'http://localhost:8000'; 
      final url = Uri.parse('$baseUrl/profile/$username');
      // Increased timeout to 90 seconds
      final response = await http.get(url).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data['recent_posts'] as List?; // Handle null posts

        // Calculate stats
        double avgLikes = 0;
        if (posts != null && posts.isNotEmpty) {
          avgLikes = posts.fold(0.0, (sum, p) => sum + (p['likes'] ?? 0)) / posts.length;
        }

        double postFrequency = 0; // in days
        if (posts != null && posts.length > 1) {
          try {
            final firstDate = DateTime.parse(posts.first['date_utc']);
            final lastDate = DateTime.parse(posts.last['date_utc']);
            final duration = firstDate.difference(lastDate);
            if (duration.inDays > 0 && posts.length > 1) {
                postFrequency = duration.inDays / (posts.length - 1);
            }
          } catch(e) {
            // Could not parse dates, ignore
          }
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
        final errorBody = json.decode(response.body);
        throw Exception('Failed to load profile. Status: ${response.statusCode}, Detail: ${errorBody['detail']}');
      }
    } catch (e) {
      if (mounted) setState(() => instaError = e.toString());
    } finally {
      if (mounted) setState(() => isLoadingInsta = false);
    }
  }

  Widget _buildSocialMediaSection() {
    // Only show if we have social media handles for this club
    if (!socialMediaHandles.containsKey(widget.clubName)) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            "📱 Social Media Presence",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        
        // Instagram Section
        if (socialMediaHandles[widget.clubName]!.containsKey('instagram')) ...[
          _buildInstagramSection(),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInstagramSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  "Instagram (@${socialMediaHandles[widget.clubName]!['instagram']})",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (isLoadingInsta)
              const Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text("Loading live stats..."),
                ],
              )
            else if (instaError != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Could not load Instagram data:\n$instaError",
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              )
            else if (instaProfile != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("Followers", "${instaProfile!['followers'] ?? 0}"),
                  _buildStatColumn("Posts", "${instaProfile!['post_count'] ?? 0}"),
                  _buildStatColumn("Following", "${instaProfile!['following'] ?? 0}"),
                ],
              ),
              if (instaPostStats != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn("Avg. Likes", instaPostStats!['avgLikes'].toStringAsFixed(0)),
                    _buildStatColumn("Post Freq.", instaPostStats!['postFrequency'] > 0 
                        ? "1 every ${instaPostStats!['postFrequency'].toStringAsFixed(1)} days"
                        : "N/A"),
                  ],
                ),
              ]
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (clubData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.clubName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ALGORITHMIC POPULARITY CALCULATION
    double overallPopularity = (clubData!['popularity'] as num).toDouble(); // Default to static score

    if (whatsappStats != null && whatsappStats!['activityScore'] != null) {
      double staticScore = (clubData!['popularity'] as num).toDouble();
      double activityScore = (whatsappStats!['activityScore'] as double);
      // Weighted average: 40% static data, 60% recent WhatsApp activity
      overallPopularity = (staticScore * 0.4) + (activityScore * 0.6);
    }

    return Scaffold(
      appBar: AppBar(title: Text(clubData!['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header and Description
            Text(clubData!['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(clubData!['category'] ?? "", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(clubData!['description'] ?? "", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            // Traditional Stats Section
            const Text("📊 Popularity & Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            
            // MODIFIED: Overall Popularity Score
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text("Overall Popularity Score"),
                subtitle: Text("${overallPopularity.toStringAsFixed(0)}/100"),
                trailing: CircularProgressIndicator(
                  value: overallPopularity / 100.0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),

            // MODIFIED: WhatsApp Activity Score
            if (whatsappStats != null && whatsappStats!['activityScore'] != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: const Text("WhatsApp Activity"),
                  subtitle: Text("${whatsappStats!['messages']} messages in the last 30 days"),
                  trailing: CircularProgressIndicator(
                    value: (whatsappStats!['activityScore'] as double) / 100.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),

            // Social Media Section
            _buildSocialMediaSection(),

            // Achievements Section
            const Divider(height: 32),
            const Text("🏆 Achievements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...((clubData!['achievements'] ?? []) as List).map((a) => 
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.orange),
                  title: Text(a['title']),
                  subtitle: Text("Year: ${a['year']}"),
                ),
              ),
            ),
            
            // Events Section
            const Divider(height: 32),
            const Text("🎭 Events", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ...((clubData!['events'] ?? []) as List).map((e) => 
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(e['name']),
                  subtitle: Text("Date: ${e['date']} | Venue: ${e['venue']}"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}