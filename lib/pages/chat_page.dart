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

    // Get user's name for greeting
    final userName = _userContext['full_name']?.toString().isNotEmpty == true
        ? _userContext['full_name']
        : _userContext['username'] ?? 'there';
    final firstName = userName.toString().split(' ').first;

    return Scaffold(
      // Use transparent background to show gradient
      backgroundColor: Colors.transparent,
      body: Container(
        // Full-screen gradient background matching the design
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    // Dark theme gradient
                    const Color(0xFF1B3D2F),
                    const Color(0xFF0D1F17),
                    AppColors.darkBackground,
                  ]
                : [
                    // Light theme gradient (matching the provided design)
                    const Color(0xFFE8F5E9), // Light green
                    const Color(0xFFC8E6C9), // Lighter green
                    const Color(0xFFA5D6A7), // Medium green
                    const Color(0xFF81C784), // Green
                  ],
            stops: isDark ? [0.0, 0.3, 1.0] : [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // HEADER SECTION
              // ---------------------------------------------------------------
              _buildHeader(context, firstName, isDark),

              // ---------------------------------------------------------------
              // CHAT CONTENT
              // ---------------------------------------------------------------
              Expanded(
                child: _isInitializing
                    ? _buildLoadingState(isDark)
                    : _messages.isEmpty
                        ? _buildEmptyState(context, firstName, isDark)
                        : _buildChatList(isDark),
              ),

              // ---------------------------------------------------------------
              // TYPING INDICATOR (shown when AI is responding)
              // ---------------------------------------------------------------
              if (_isLoading) _buildTypingIndicator(isDark),

              // ---------------------------------------------------------------
              // MESSAGE INPUT SECTION
              // ---------------------------------------------------------------
              _buildMessageInput(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section with profile picture and greeting
  Widget _buildHeader(BuildContext context, String firstName, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile picture
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _buildProfilePicture(isDark),
          ),

          // Reset chat button
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            onPressed: _resetChat,
            tooltip: 'Start new chat',
          ),
        ],
      ),
    );
  }

  /// Builds the user's profile picture widget
  Widget _buildProfilePicture(bool isDark) {
    final imageUrl = _userProfile?['profile_image_url'];

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultAvatar(isDark),
              )
            : _buildDefaultAvatar(isDark),
      ),
    );
  }

  /// Builds the default avatar when no profile picture is available
  Widget _buildDefaultAvatar(bool isDark) {
    final initials = _getInitials();
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  /// Gets the user's initials for the default avatar
  String _getInitials() {
    final fullName = _userContext['full_name']?.toString() ?? '';
    final username = _userContext['username']?.toString() ?? '';
    final name = fullName.isNotEmpty ? fullName : username;

    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Builds the empty state when no messages exist
  Widget _buildEmptyState(BuildContext context, String firstName, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Greeting text
          Text(
            'Hi $firstName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          // Main question text (matching the design)
          Text(
            "What's been on\nyour mind lately?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          // Suggestion chips
          _buildSuggestionChips(isDark),
        ],
      ),
    );
  }

  /// Builds suggestion chips for quick questions
  Widget _buildSuggestionChips(bool isDark) {
    final suggestions = [
      'How are my glucose levels?',
      'What should I eat today?',
      'Tips for better sleep',
      'Exercise recommendations',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return GestureDetector(
          onTap: () {
            _messageController.text = suggestion;
            _sendMessage();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            child: Text(
              suggestion,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the loading state while initializing
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? Colors.white70 : AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your health data...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the chat messages list
  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, isDark);
      },
    );
  }

  /// Builds a single message bubble
  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.9)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// Builds the typing indicator animation
  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                // Calculate offset for bouncing dots animation
                final offset = (index * 0.2);
                final value = (_typingAnimationController.value + offset) % 1.0;
                final bounce = (value < 0.5 ? value : 1.0 - value) * 8;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.translate(
                    offset: Offset(0, -bounce),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white54
                            : AppColors.primary.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  /// Builds the message input section at the bottom
  Widget _buildMessageInput(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
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
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
