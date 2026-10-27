import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the Paril World MongoDB API.
///
/// The API runs on the local network at port 3001.
/// Automatically detects Web (localhost) vs Android Emulator (10.0.2.2).
/// When testing on a real device on the same Wi-Fi, you can set your PC IP.
class MongoDbService {
  /// Render production API URL.
  static const String _productionUrl = 'https://parils-world.onrender.com';

  static String get _baseUrl => _productionUrl;

  static final MongoDbService _instance = MongoDbService._internal();
  factory MongoDbService() => _instance;
  MongoDbService._internal();

  final _client = http.Client();

  // ── Leaderboard ──────────────────────────────────────────────────────────

  /// Fetch the top 20 leaderboard entries.
  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/leaderboard'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Submit a new score to the leaderboard.
  Future<bool> submitScore({
    required String playerName,
    required String role,
    required int score,
    required int iceCreamCount,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/leaderboard'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'playerName': playerName,
              'role': role,
              'score': score,
              'iceCreamCount': iceCreamCount,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Players ───────────────────────────────────────────────────────────────

  /// Register or update a player (Friends/Family role with a name).
  Future<bool> registerPlayer({
    required String name,
    required String role,
    String? deviceId,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl/players'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'role': role,
              if (deviceId case final id?) 'deviceId': id,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String playerName;
  final String role;
  final int score;
  final int iceCreamCount;
  final DateTime? submittedAt;

  const LeaderboardEntry({
    required this.playerName,
    required this.role,
    required this.score,
    required this.iceCreamCount,
    this.submittedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerName: json['playerName'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'unknown',
      score: (json['score'] as num?)?.toInt() ?? 0,
      iceCreamCount: (json['iceCreamCount'] as num?)?.toInt() ?? 0,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
    );
  }
}
