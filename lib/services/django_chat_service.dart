/// ============================================================================
/// DJANGO CHAT SERVICE - Backend-Based Chat for DiaCare
/// ============================================================================
///
/// This service connects to the Django backend's AI chat endpoints
/// instead of calling Groq directly from the Flutter app.
///
/// Benefits of backend-based approach:
/// - API key stays secure on server
/// - Better logging and monitoring
/// - Easier to change AI providers
/// - Consistent conversation history across devices
///
/// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Check if this is a user message
  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Chat session model
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Chat',
      createdAt: DateTime.parse(json['created_at']),
      // last_message_at may not exist, fallback to created_at
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'])
          : DateTime.parse(json['created_at']),
    );
  }
}

/// Django-based chat service
class DjangoChatService {
  String? _accessToken;

  /// Load access token from SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  /// Get headers with auth token
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }

  /// Send a chat message and get AI response
  Future<ChatMessage> sendMessage({
    required String message,
    String? sessionId,
  }) async {
    await _loadToken();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chat}'),
            headers: _getHeaders(),
            body: jsonEncode({
              'message': message,
              if (sessionId != null) 'session_id': sessionId,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend returns { success: true, data: { response, timestamp, ... } }
        final data = responseData['data'] ?? responseData;
        return ChatMessage.fromJson({
          'id': data['message_id'] ?? data['id'],
          'role': 'assistant',
          'content': data['response'],
          'timestamp': data['timestamp'],
        });
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Failed to send message: ${error['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  /// Get chat history for a session
  Future<List<ChatMessage>> getChatHistory({String? sessionId}) async {
    await _loadToken();

    try {
      final uri = sessionId != null
          ? '${ApiConfig.baseUrl}${ApiConfig.chatHistory}?session_id=$sessionId'
          : '${ApiConfig.baseUrl}${ApiConfig.chatHistory}';

      final response = await http
          .get(
            Uri.parse(uri),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend returns { success: true, data: { messages: [...] } }
        final data = responseData['data'] ?? responseData;
        final List<dynamic> messages = data['messages'] ?? data;
        return messages.map((item) => ChatMessage.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get chat history: ${e.toString()}');
    }
  }

  /// Get all chat sessions
  Future<List<ChatSession>> getSessions() async {
    await _loadToken();

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatSessions}'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Backend returns { success: true, data: { sessions: [...] } }
        final data = responseData['data'] ?? responseData;
        final List<dynamic> sessions = data['sessions'] ?? data;
        return sessions.map((item) => ChatSession.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get sessions: ${e.toString()}');
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    await _loadToken();

    try {
      // Backend expects DELETE /chat/sessions/<session_id>/
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatDeleteSession}$sessionId/'),
            headers: _getHeaders(),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete session');
      }
    } catch (e) {
      throw Exception('Failed to delete session: ${e.toString()}');
    }
  }

  /// Clear all chat history (local only, doesn't affect backend)
  Future<void> clearChatHistory() async {
    // This would typically clear local cache
    // For backend-based chat, history is managed server-side
  }
}
