// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String? _adminToken;

  // ✅ FIX 1: baseUrl getter is on ApiService, not ApiException
  String get baseUrl => AppConstants.baseUrl;

  void setToken(String? token) => _token = token;
  void setAdminToken(String? token) => _adminToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get _adminHeaders => {
        'Content-Type': 'application/json',
        if (_adminToken != null) 'Authorization': 'Bearer $_adminToken',
      };

  // ── INTERNAL HELPER ─────────────────────────────────────────────────────────
  Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        'Failed to parse server response (status ${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
  }

  // ── HEALTH ──────────────────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('${AppConstants.baseUrl}/health'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── AUTH ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String ageGroup,
    required String expertiseLevel,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'age_group': ageGroup,
        'expertise_level': expertiseLevel,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw ApiException(data['error'] ?? 'Registration failed',
          statusCode: res.statusCode);
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(data['error'] ?? 'Login failed',
          statusCode: res.statusCode);
    }
    _token = data['token'];
    return data;
  }

  Future<void> logout() async {
    if (_token == null) return;
    await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/logout'),
      headers: _headers,
    );
    _token = null;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/auth/me'),
      headers: _headers,
    );
    if (res.statusCode == 401) throw ApiException('Unauthorized', statusCode: 401);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}/auth/profile'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/change-password'),
      headers: _headers,
      body: jsonEncode(
          {'old_password': oldPassword, 'new_password': newPassword}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── CHAT ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> chat({
    required String query,
    required String characterId,
    required String sessionId,
  }) async {
    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/user/chat'),
          headers: _headers,
          body: jsonEncode({
            'query': query,
            'character_id': characterId,
            'session_id': sessionId,
          }),
        )
        .timeout(const Duration(seconds: 6000));
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(data['error'] ?? 'Chat failed');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> chatAll({
    required String query,
    required String sessionId,
  }) async {
    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/chat/all'),
          headers: _headers,
          body: jsonEncode({'query': query, 'session_id': sessionId}),
        )
        .timeout(const Duration(seconds: 12000));
    if (res.statusCode != 200) {
      throw ApiException('Failed to get multi-character response');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> submitFeedback({
    required String query,
    required double rating,
    required String characterId,
    required String sessionId,
    String comment = '',
  }) async {
    await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/feedback'),
      headers: _headers,
      body: jsonEncode({
        'query': query,
        'rating': rating,
        'character_id': characterId,
        'session_id': sessionId,
        if (comment.isNotEmpty) 'comment': comment,
      }),
    );
  }

  Future<Map<String, dynamic>> getFeedbacks() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/feedback'),
      headers: _headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── HISTORY ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getHistory({
    String? characterId,
    String? topic,
    String? search,
    int limit = 30,
    int offset = 0,
    String? sessionId,
  }) async {
    // Build query params — no hardcoded values in base URL
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (characterId != null) 'character_id': characterId,
      if (topic != null) 'topic': topic,
      if (search != null) 'search': search,
      if (sessionId != null) 'session_id': sessionId,
    };

    final uri = Uri.parse('${AppConstants.baseUrl}/history')
        .replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 401) throw ApiException('Unauthorized', statusCode: 401);
    if (res.statusCode != 200) throw ApiException('Failed to load history', statusCode: res.statusCode);

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Safety check: if backend returned docs instead of real data, token is missing
    if (data.containsKey('info') && !data.containsKey('records')) {
      throw ApiException('Token missing or invalid — received API docs instead of history');
    }

    return data;
  }

  Future<List<dynamic>> getHistorySessions() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/history/sessions'),
      headers: _headers,
    );
    if (res.statusCode == 401) throw ApiException('Unauthorized', statusCode: 401);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['sessions'] as List?) ?? [];
  }

 Future<Map<String, dynamic>> getHistoryStats() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/history/stats'),
      headers: _headers,
    );
    if (res.statusCode == 401) throw ApiException('Unauthorized', statusCode: 401);
    if (res.statusCode != 200) throw ApiException('Failed to load history stats', statusCode: res.statusCode);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  
  Future<void> deleteSession(String sessionId) async {
    await http.delete(
      Uri.parse('${AppConstants.baseUrl}/history/session/$sessionId'),
      headers: _headers,
    );
  }

  // ── QUIZ ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateQuiz({
    required String characterId,
    required String quizType,
    required String difficulty,
    required String sessionId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/quiz/generate'),
      headers: _headers,
      body: jsonEncode({
        'character_id': characterId,
        'quiz_type': quizType,
        'difficulty': difficulty,
        'session_id': sessionId,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitQuizAnswer({
    required String sessionId,
    required String quizType,
    required dynamic userAnswer,
    required dynamic correctAnswer,
    required int xpReward,
    String? challengeId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/quiz/submit'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'quiz_type': quizType,
        'user_answer': userAnswer,
        'correct_answer': correctAnswer,
        'xp_reward': xpReward,
        if (challengeId != null) 'challenge_id': challengeId,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLeaderboard() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/quiz/leaderboard'),
      headers: _headers,
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['leaderboard'] as List?) ?? [];
  }
// ── PREDICTED TOPICS ────────────────────────────────────────────────────────

Future<Map<String, dynamic>> predictTopics({
  required String sessionId,
  required String currentTopic,
  required String characterId,
  int topN = 5,
}) async {
  final res = await http.post(
    Uri.parse('${AppConstants.baseUrl}/predict/topics'),
    headers: _headers,
    body: jsonEncode({
      'session_id': sessionId,
      'current_topic': currentTopic,
      'character_id': characterId,
      'top_n': topN,
    }),
  );
  return jsonDecode(res.body) as Map<String, dynamic>;
}
  // ── EXPERTISE ───────────────────────────────────────────────────────────────

  Future<void> setExpertiseLevel(String sessionId, String level) async {
    await http.post(
      Uri.parse('${AppConstants.baseUrl}/user/expertise'),
      headers: _headers,
      body: jsonEncode({'session_id': sessionId, 'level': level}),
    );
  }

  // ── FOLKLORE ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAllFolklore() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/folklore/all'),
      headers: _headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // alias used by folklore_screen.dart
  Future<Map<String, dynamic>> getFolklore() => getAllFolklore();

  Future<Map<String, dynamic>> findFolklore(String query) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/folklore/find'),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── CAUSAL CHAIN ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCausalChain(String query) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/causal/chain'),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── ANOMALY ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> checkAnomaly(String query) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/anomaly/check'),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── VR DISCOVERY ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> discoverVrSites({
    required String sessionId,
    required String currentTopic,
    required String characterId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/vr/discover'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'current_topic': currentTopic,
        'character_id': characterId,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── CRITICAL THINKING ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCriticalQuestion({
    required String sessionId,
    required String characterId,
    required String topic,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/critical/question'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'character_id': characterId,
        'topic': topic,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── SESSION MEMORY ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSessionMemory(String sessionId) async {
    final res = await http.get(
      Uri.parse(
          '${AppConstants.baseUrl}/memory/history?session_id=$sessionId'),
      headers: _headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
Future<List<int>> downloadReport({String location = 'all'}) async {
  final res = await http.get(
    Uri.parse('${AppConstants.baseUrl}/report/user?location=$location'),
    headers: _headers,
  );

  if (res.statusCode == 401) throw ApiException('Unauthorized', statusCode: 401);
  if (res.statusCode != 200) throw ApiException('Failed to download report', statusCode: res.statusCode);

  return res.bodyBytes; // <-- Return raw bytes instead of JSON
}
    
  
  // ── ADMIN ───────────────────────────────────────────────────────────────────
  // NOTE: All admin methods call /api/admin/* JSON endpoints (NOT the HTML
  // dashboard at /admin/*). The matching Flask routes are added in the
  // "Admin JSON API" section of inference_api.py (see companion file).
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /api/admin/login  — returns {success, token, message}
  Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = _decodeJson(res);
    if (res.statusCode != 200) {
      throw ApiException(data['error'] ?? 'Admin login failed',
          statusCode: res.statusCode);
    }
    _adminToken = data['token'];
    return data;
  }

  /// GET /api/admin/overview
  Future<Map<String, dynamic>> adminGetOverview() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/admin/overview'),
      headers: _adminHeaders,
    );
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// GET /api/admin/metrics
  Future<Map<String, dynamic>> adminGetMetrics() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/admin/metrics'),
      headers: _adminHeaders,
    );
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// GET /api/admin/users
  Future<Map<String, dynamic>> adminGetUsers() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/admin/users'),
      headers: _adminHeaders,
    );
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// GET /api/admin/feedback
  Future<Map<String, dynamic>> adminGetFeedbacks() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/admin/feedback'),
      headers: _adminHeaders,
    );
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// GET /api/admin/chats
  Future<Map<String, dynamic>> adminGetRecentChats({
    String search = '',
    String characterFilter = 'all',
    int page = 1,
  }) async {
    final params = <String, String>{
      if (search.isNotEmpty) 'q': search,
      'char': characterFilter,
      'page': page.toString(),
    };
    final uri = Uri.parse('${AppConstants.baseUrl}/api/admin/chats')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _adminHeaders);
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// GET /api/admin/analytics
  Future<Map<String, dynamic>> adminGetAnalytics() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/admin/analytics'),
      headers: _adminHeaders,
    );
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// GET /api/admin/anomalies
  Future<Map<String, dynamic>> adminGetAnomalies() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/admin/anomalies'),
      headers: _adminHeaders,
    );
    if (res.statusCode == 401) {
      throw ApiException('Admin session expired', statusCode: 401);
    }
    return _decodeJson(res);
  }

  /// POST /api/admin/logout
  Future<void> adminLogout() async {
    await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/admin/logout'),
      headers: _adminHeaders,
    );
    _adminToken = null;
  }
}
