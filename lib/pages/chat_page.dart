/// ============================================================================
/// CHAT PAGE - AI-Powered Diabetes Health Assistant
/// ============================================================================
///
/// This page provides an interactive chat interface for users to communicate
/// with an AI-powered diabetes health assistant. The AI provides personalized
/// advice based on the user's health data stored in the app.
///
/// Features:
/// - Beautiful gradient background matching app theme
/// - Real-time chat with AI using Google Gemini
/// - User health context automatically sent to AI
/// - Theme-aware design (supports light/dark mode)
/// - Smooth animations and modern UI
/// - User profile picture display
///
/// Design based on modern chat interfaces with green gradient theme
/// to match the DiaCare branding.
///
/// Dependencies:
/// - ai_chat_service.dart: Handles AI communication
/// - data_service_supabase.dart: Fetches user health data
/// ============================================================================

import 'package:flutter/material.dart';
import '../services/ai_chat_service.dart';
import '../services/data_service_supabase.dart';
import '../utils/constants.dart';

/// ============================================================================
/// CHAT PAGE WIDGET
/// ============================================================================
/// Main stateful widget for the AI chat interface
class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

/// ============================================================================
/// CHAT PAGE STATE
/// ============================================================================
/// Manages the state of the chat interface including messages,
/// loading states, and user interactions
class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // CONTROLLERS & SERVICES
  // ---------------------------------------------------------------------------

  /// Text controller for the message input field
  final TextEditingController _messageController = TextEditingController();

  /// Scroll controller for auto-scrolling chat to bottom
  final ScrollController _scrollController = ScrollController();

  /// AI Chat Service for communicating with Gemini AI
  final AIChatService _aiService = AIChatService();

  // ---------------------------------------------------------------------------
  // STATE VARIABLES
  // ---------------------------------------------------------------------------

  /// List of chat messages (both user and AI)
  final List<ChatMessage> _messages = [];

  /// Flag indicating if AI is currently generating a response
  bool _isLoading = false;

  /// Flag indicating if initial data is being loaded
  bool _isInitializing = true;

  /// User's health data context for AI
  Map<String, dynamic> _userContext = {};

  /// User's profile data for display
  Map<String, dynamic>? _userProfile;

  /// Animation controller for typing indicator
  late AnimationController _typingAnimationController;

  // ---------------------------------------------------------------------------
  // LIFECYCLE METHODS
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Initialize typing animation
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Load user data for context
    _loadUserContext();
  }

  @override
  void dispose() {
    // Clean up resources
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA LOADING METHODS
  // ---------------------------------------------------------------------------

  /// Loads the user's health data to provide context to the AI
  /// This includes profile, glucose readings, health cards, etc.
  Future<void> _loadUserContext() async {
    try {
      final dataService = getIt<DataService>();

      // Get user profile
      final profile = await dataService.getCurrentUser();
      _userProfile = profile;

      // Get diabetic profile
      final diabeticProfile = await dataService.getDiabeticProfile();

      // Get latest glucose reading
      final latestGlucose = await dataService.getLatestGlucoseReading();

      // Get recent glucose readings (last 7)
      final recentReadings = await dataService.getGlucoseReadings(limit: 7);

      // Get today's health cards
      final healthCards = await dataService.getHealthCards();

      // Calculate age from date of birth if available
      String age = 'Not specified';
      if (profile?['date_of_birth'] != null) {
        try {
          final dob = DateTime.parse(profile!['date_of_birth']);
          final now = DateTime.now();
          age = (now.year - dob.year).toString();
        } catch (_) {}
      }

      // Build comprehensive user context
      setState(() {
        _userContext = {
          // Profile data
          'full_name': profile?['full_name'] ?? '',
          'username': profile?['username'] ?? '',
          'email': profile?['email'] ?? '',
          'age': age,
          'gender': profile?['gender'] ?? 'Not specified',
          'height': profile?['height'] ?? 'Not specified',
          'weight': profile?['weight'] ?? 'Not specified',
          'profile_image_url': profile?['profile_image_url'],

          // Diabetic profile
          'diabetic_type': diabeticProfile?['diabetic_type'] ?? 'Type 2',
          'treatment_type':
              diabeticProfile?['treatment_type'] ?? 'Not specified',
          'min_glucose': diabeticProfile?['min_glucose'] ?? 70,
          'max_glucose': diabeticProfile?['max_glucose'] ?? 180,

          // Latest glucose
          'latest_glucose': latestGlucose?['value'] ?? 'No reading',
          'glucose_unit': latestGlucose?['unit'] ?? 'mg/dL',
          'latest_reading_type': latestGlucose?['reading_type'] ?? '',

          // Health cards
          'health_cards': healthCards,

          // Recent readings
          'recent_glucose_readings': recentReadings,
        };
        _isInitializing = false;
      });
    } catch (e) {
      // Handle error gracefully
      setState(() {
        _isInitializing = false;
        _userContext = {
          'full_name': 'User',
          'diabetic_type': 'Type 2',
          'min_glucose': 70,
          'max_glucose': 180,
        };
      });
    }
  }

  // ---------------------------------------------------------------------------
  // CHAT METHODS
  // ---------------------------------------------------------------------------

  /// Sends a message to the AI and handles the response
  Future<void> _sendMessage() async {
    // Get the message text and trim whitespace
    final messageText = _messageController.text.trim();

    // Don't send empty messages
    if (messageText.isEmpty) return;

    // Clear the input field
    _messageController.clear();

    // Add user's message to the chat
    setState(() {
      _messages.add(ChatMessage.user(messageText));
      _isLoading = true;
    });

    // Scroll to bottom to show new message
    _scrollToBottom();

    try {
      // Send message to AI and get response
      final response = await _aiService.sendMessage(
        message: messageText,
        userContext: _userContext,
      );

      // Add AI's response to the chat
      setState(() {
        _messages.add(ChatMessage.ai(response));
        _isLoading = false;
      });

      // Scroll to bottom to show AI response
      _scrollToBottom();
    } on AIChatException catch (e) {
      // Handle AI-specific errors
      setState(() {
        _messages.add(ChatMessage.ai(
          "I'm sorry, I couldn't process your request. Please try again. Error: ${e.message}",
        ));
        _isLoading = false;
      });
    } catch (e) {
      // Handle general errors
      setState(() {
        _messages.add(ChatMessage.ai(
          "I'm having trouble connecting right now. Please check your internet connection and try again.",
        ));
        _isLoading = false;
      });
    }
  }

  /// Scrolls the chat view to the bottom
  void _scrollToBottom() {
    // Use a small delay to ensure the list has updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Resets the chat conversation
  void _resetChat() {
    setState(() {
      _messages.clear();
      _aiService.resetChat();
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD METHODS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Get theme information for responsive styling
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header matching Dashboard style with color
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                top: 8,
                bottom: 4,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.insulinColor.withOpacity(isDark ? 0.15 : 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.purpleGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.chat,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.insulinColor.withOpacity(0.2),
                              AppColors.insulinColor.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.insulinColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppColors.insulinColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.chat,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.chatDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                decoration: InputDecoration(
                  hintText: 'Describe your question...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
