// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final Map<String, List<ChatMessage>> _conversations = {};
  String _activeCharacterId = 'king';
  bool _isLoading = false;
  String? _error;
  String? _sessionId;
  String? _userId;

  String get activeCharacterId => _activeCharacterId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Key: userId_characterId so each user has separate history
  String get _convKey => '${_userId ?? 'guest'}_$_activeCharacterId';

  List<ChatMessage> get currentMessages => _conversations[_convKey] ?? [];

  // Called by ProxyProvider in main.dart when auth state changes
  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (userId == null) _conversations.clear();
    notifyListeners();
  }

  void setSessionId(String id) {
    _sessionId = id;
  }

  void setCharacter(String characterId) {
    _activeCharacterId = characterId;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Loads chat history from the server and restores it into memory.
  /// FIX: tries both 'history' and 'records' as the response key.
  Future<void> loadHistoryFromServer() async {
    if (_userId == null) return;
    try {
      final data = await _api.getHistory(limit: 100, offset: 0);

      // Backend may return key 'history', 'records', or 'messages'
      final rawList = data['history'] as List?
          ?? data['records'] as List?
          ?? data['messages'] as List?
          ?? [];

      final records = rawList
          .map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList();

      // Group by userId_characterId
      final Map<String, List<ChatMessage>> restored = {};
      for (final r in records) {
        final key = '${_userId}_${r.characterId}';
        restored[key] ??= [];
        restored[key]!.add(ChatMessage(
          id: '${r.msgId}_q',
          content: r.question,
          isUser: true,
          timestamp: r.timestamp,
          characterId: r.characterId,
        ));
        restored[key]!.add(ChatMessage(
          id: '${r.msgId}_a',
          content: r.answer,
          isUser: false,
          timestamp: r.timestamp,
          characterId: r.characterId,
          characterName: r.characterName,
          confidence: r.confidence,
          topic: r.topic,
          intent: r.intent,
        ));
      }

      // Sort chronologically
      for (final msgs in restored.values) {
        msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      _conversations.addAll(restored);
      notifyListeners();
    } catch (e) {
      debugPrint('loadHistoryFromServer error: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Auto-generate session if not set
    _sessionId ??= '${_userId ?? 'guest'}_${DateTime.now().millisecondsSinceEpoch}';

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      characterId: _activeCharacterId,
    );

    _conversations[_convKey] ??= [];
    _conversations[_convKey]!.add(userMsg);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.chat(
        query: text.trim(),
        characterId: _activeCharacterId,
        sessionId: _sessionId!,
      );

      final botMsg = ChatMessage.fromApiResponse(response, text);
      _conversations[_convKey]!.add(botMsg);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
   } catch (e) {
      debugPrint('API ERROR TYPE: ${e.runtimeType}');
      debugPrint('API ERROR: $e');
      _error = 'Failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitFeedback(String query, double rating) async {
    if (_sessionId == null) return;
    try {
      await _api.submitFeedback(
        query: query,
        rating: rating,
        characterId: _activeCharacterId,
        sessionId: _sessionId!,
      );
    } catch (_) {}
  }

  void clearConversation() {
    _conversations[_convKey] = [];
    notifyListeners();
  }

  void clearAll() {
    _conversations.clear();
    notifyListeners();
  }
}