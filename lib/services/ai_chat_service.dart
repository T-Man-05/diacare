/// ============================================================================
/// AI CHAT SERVICE - Groq AI Integration for DiaCare
/// ============================================================================
///
/// This service manages AI-powered chat functionality for DiaCare using
/// Groq's ultra-fast LLM API. It provides personalized diabetes health advice
/// by incorporating the user's health data as context.
///
/// Features:
/// - Groq AI integration for fast, intelligent health conversations
/// - Automatic context injection with user's diabetes data
/// - Role-based prompting (AI acts as a diabetes specialist)
/// - Chat history management for context-aware responses
///
/// Usage:
///   final aiService = AIChatService();
///   final response = await aiService.sendMessage(
///     message: "What should I eat for breakfast?",
///     userContext: {...}, // User's health data
///   );
///
/// Security Note:
/// - API key should ideally be stored securely (not hardcoded in production)
/// - User data is sent to Groq's API - ensure HIPAA compliance if needed
/// ============================================================================

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// ============================================================================
/// AI CHAT SERVICE CLASS
/// ============================================================================
/// Handles all AI chat operations including message sending, context building,
/// and chat history management.
class AIChatService {
  // ---------------------------------------------------------------------------
  // CONSTANTS & CONFIGURATION
  // ---------------------------------------------------------------------------

  /// Groq API Key - loaded from .env file for security
  /// NOTE: Never hardcode API keys in production code
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Groq API endpoint (OpenAI-compatible)
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Model to use (Llama 3.3 70B - latest and most capable)
  static const String _modelName = 'llama-3.3-70b-versatile';

  // ---------------------------------------------------------------------------
  // PRIVATE MEMBERS
  // ---------------------------------------------------------------------------

  /// HTTP client for API requests
  final http.Client _client = http.Client();

  /// Chat history for maintaining conversation context
  final List<Map<String, String>> _chatHistory = [];

  /// System prompt for the AI
  String? _systemPrompt;

  /// Flag to track if service is initialized
  bool _isInitialized = false;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR & INITIALIZATION
  // ---------------------------------------------------------------------------

  /// Creates a new AIChatService instance
  AIChatService() {
    _isInitialized = true;
  }

  // ---------------------------------------------------------------------------
  // PUBLIC METHODS
  // ---------------------------------------------------------------------------

  /// Sends a message to the AI and receives a response
  ///
  /// Parameters:
  /// - [message]: The user's message/question
  /// - [userContext]: Map containing user's health data for context
  ///
  /// Returns:
  /// - AI-generated response as a String
  ///
  /// Throws:
  /// - [AIChatException] if the API call fails
  Future<String> sendMessage({
    required String message,
    required Map<String, dynamic> userContext,
  }) async {
    try {
      // Build system prompt on first message
      if (_systemPrompt == null) {
        _systemPrompt = _buildSystemPrompt(userContext);
      }

      // Add user message to history
      _chatHistory.add({
        'role': 'user',
        'content': message,
      });

      // Build the messages array for the API
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': _systemPrompt!,
        },
        ..._chatHistory,
      ];

      // Make the API request to Groq
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024,
          'top_p': 0.95,
        }),
      );

      // Check for successful response
      if (response.statusCode != 200) {
        // Parse error message if available
        String errorMessage =
            'API request failed with status ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['error'] != null) {
            errorMessage = errorBody['error']['message'] ?? errorMessage;
          }
        } catch (_) {}
        throw AIChatException(errorMessage);
      }

      // Parse the response
      final responseBody = jsonDecode(response.body);
      final choices = responseBody['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        throw AIChatException('Empty response received from AI');
      }

      // Extract the assistant's message
      final assistantMessage = choices[0]['message']['content'] as String?;

      if (assistantMessage == null || assistantMessage.isEmpty) {
        throw AIChatException('Empty response content from AI');
      }

      // Add assistant response to history
      _chatHistory.add({
        'role': 'assistant',
        'content': assistantMessage,
      });

      return assistantMessage;
    } on AIChatException {
      // Re-throw AIChatException as-is
      rethrow;
    } catch (e) {
      // Handle general errors
      throw AIChatException('Failed to get AI response: $e');
    }
  }

  /// Resets the chat session (starts a new conversation)
  /// Call this when user wants to start fresh
  void resetChat() {
    _chatHistory.clear();
    _systemPrompt = null;
  }

  /// Checks if the service is ready to use
  bool get isReady => _isInitialized;

  // ---------------------------------------------------------------------------
  // PRIVATE HELPER METHODS
  // ---------------------------------------------------------------------------

  /// Builds the system prompt with user's health context
  ///
  /// This prompt establishes the AI's role as a diabetes specialist
  /// and provides all relevant user health data for personalized advice
  String _buildSystemPrompt(Map<String, dynamic> userContext) {
    // Extract user data from context
    final userName =
        userContext['full_name'] ?? userContext['username'] ?? 'User';
    final diabeticType = userContext['diabetic_type'] ?? 'Type 2';
    final treatmentType = userContext['treatment_type'] ?? 'Not specified';
    final minGlucose = userContext['min_glucose'] ?? 70;
    final maxGlucose = userContext['max_glucose'] ?? 180;
    final latestGlucose = userContext['latest_glucose'] ?? 'No recent reading';
    final glucoseUnit = userContext['glucose_unit'] ?? 'mg/dL';
    final age = userContext['age'] ?? 'Not specified';
    final gender = userContext['gender'] ?? 'Not specified';
    final height = userContext['height'] ?? 'Not specified';
    final weight = userContext['weight'] ?? 'Not specified';

    // Build health cards summary
    final healthCards = userContext['health_cards'] as List<dynamic>? ?? [];
    String healthSummary = '';
    for (final card in healthCards) {
      if (card is Map<String, dynamic>) {
        healthSummary +=
            '- ${card['title']}: ${card['value']} ${card['unit']}\n';
      }
    }

    // Build recent glucose readings summary
    final recentReadings =
        userContext['recent_glucose_readings'] as List<dynamic>? ?? [];
    String readingsSummary = '';
    for (final reading in recentReadings.take(5)) {
      if (reading is Map<String, dynamic>) {
        readingsSummary +=
            '- ${reading['value']} ${reading['unit']} (${reading['reading_type']}) at ${reading['recorded_at']}\n';
      }
    }

    // Construct the comprehensive system prompt
    return '''
You are DiaCare AI Assistant, a knowledgeable and empathetic virtual diabetes specialist. Your role is to provide personalized health advice and support for diabetes management.

## YOUR RESPONSIBILITIES:
1. Provide accurate, evidence-based diabetes health information
2. Offer personalized advice based on the user's health data
3. Help interpret glucose readings and health metrics
4. Suggest dietary recommendations appropriate for diabetics
5. Encourage healthy lifestyle choices
6. Remind about medication adherence when relevant
7. Provide emotional support and motivation

## IMPORTANT GUIDELINES:
- Always be empathetic, supportive, and encouraging
- Provide practical, actionable advice
- If glucose levels are concerning (below $minGlucose or above $maxGlucose $glucoseUnit), express appropriate concern
- Never replace professional medical advice - recommend consulting a doctor for serious concerns
- Keep responses concise but informative (2-3 paragraphs max)
- Use simple language, avoid excessive medical jargon
- Be culturally sensitive and respectful

## USER PROFILE:
- Name: $userName
- Diabetes Type: $diabeticType
- Treatment: $treatmentType
- Target Glucose Range: $minGlucose - $maxGlucose $glucoseUnit
- Age: $age
- Gender: $gender
- Height: $height cm
- Weight: $weight kg

## LATEST HEALTH DATA:
- Current Glucose: $latestGlucose $glucoseUnit

## TODAY'S HEALTH METRICS:
$healthSummary

## RECENT GLUCOSE READINGS:
$readingsSummary

## CONVERSATION STYLE:
- Be warm and friendly, like a caring health companion
- Use the user's name occasionally
- Celebrate their successes
- Gently address areas for improvement
- Ask follow-up questions to better understand their needs

Remember: You are here to support, educate, and motivate - not to diagnose or prescribe.
''';
  }
}

/// ============================================================================
/// CHAT MESSAGE MODEL
/// ============================================================================
/// Represents a single message in the chat conversation
class ChatMessage {
  /// Unique identifier for the message
  final String id;

  /// The message text content
  final String content;

  /// Whether this message is from the user (true) or AI (false)
  final bool isUser;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Creates a new ChatMessage
  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a user message
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
    );
  }

  /// Creates an AI message
  factory ChatMessage.ai(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
    );
  }
}

/// ============================================================================
/// AI CHAT EXCEPTION
/// ============================================================================
/// Custom exception for AI chat errors
class AIChatException implements Exception {
  /// Error message
  final String message;

  /// Creates a new AIChatException
  AIChatException(this.message);

  @override
  String toString() => 'AIChatException: $message';
}
