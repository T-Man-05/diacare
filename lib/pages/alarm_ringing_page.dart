/// ============================================================================
/// ALARM RINGING PAGE - Active Alarm Screen for DiaCare
/// ============================================================================
///
/// This screen is displayed when an alarm/reminder time is reached.
/// It provides a full-screen interface for the user to stop or snooze
/// the active alarm.
///
/// Features:
/// - Pulsing animated ring indicating active alarm
/// - Large, readable time display
/// - Alarm title and repeat information
/// - Slide-to-stop action for primary dismissal
/// - Snooze button for temporary delay
/// - Theme-aware design (light/dark mode support)
///
/// Usage:
///   Navigator.push(
///     context,
///     MaterialPageRoute(
///       builder: (context) => AlarmRingingPage(
///         alarmTime: '07:00',
///         alarmLabel: 'Wake up',
///         repeatType: 'Everyday',
///         onStop: () => ...,
///         onSnooze: () => ...,
///       ),
///     ),
///   );
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// ============================================================================
/// ALARM RINGING PAGE WIDGET
/// ============================================================================
/// Main stateful widget for the alarm ringing screen
class AlarmRingingPage extends StatefulWidget {
  /// The time to display (e.g., "07:00")
  final String alarmTime;

  /// The alarm label/title (e.g., "Wake up", "Take medication")
  final String alarmLabel;

  /// The repeat type (e.g., "Everyday", "Mon-Fri", "Once")
  final String repeatType;

  /// Callback when alarm is stopped/dismissed
  final VoidCallback? onStop;

  /// Callback when alarm is snoozed
  final VoidCallback? onSnooze;

  /// Snooze duration in minutes (default: 9 minutes)
  final int snoozeDuration;

  const AlarmRingingPage({
    Key? key,
    required this.alarmTime,
    required this.alarmLabel,
    this.repeatType = 'Once',
    this.onStop,
    this.onSnooze,
    this.snoozeDuration = 9,
  }) : super(key: key);

  @override
  State<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

/// ============================================================================
/// ALARM RINGING PAGE STATE
/// ============================================================================
/// Manages animations and interactions for the alarm screen
class _AlarmRingingPageState extends State<AlarmRingingPage>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // ANIMATION CONTROLLERS
  // ---------------------------------------------------------------------------

  /// Controller for the pulsing ring animation
  late AnimationController _pulseController;

  /// Controller for the outer expanding halo effect
  late AnimationController _haloController;

  /// Controller for the slide-to-stop button
  late AnimationController _slideController;

  // ---------------------------------------------------------------------------
  // ANIMATIONS
  // ---------------------------------------------------------------------------

  /// Animation for the inner pulse effect
  late Animation<double> _pulseAnimation;

  /// Animation for the outer halo expansion
  late Animation<double> _haloAnimation;

  /// Animation for halo opacity (fades out as it expands)
  late Animation<double> _haloOpacityAnimation;

  // ---------------------------------------------------------------------------
  // STATE VARIABLES
  // ---------------------------------------------------------------------------

  /// Current slide position (0.0 to 1.0)
  double _slidePosition = 0.0;

  /// Whether the alarm has been dismissed
  bool _isDismissed = false;

  // ---------------------------------------------------------------------------
  // LIFECYCLE METHODS
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Set the status bar to transparent for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize pulse animation controller
    // Creates a subtle breathing effect for the main ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pulse animation: scales from 1.0 to 1.08 for subtle effect
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize halo animation controller
    // Creates an expanding ring that fades out
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Halo expansion: scales from 1.0 to 1.5
    _haloAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _haloController,
        curve: Curves.easeOut,
      ),
    );

    // Halo opacity: fades from 0.6 to 0.0 as it expands
    _haloOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _haloController,
        curve: Curves.easeOut,
      ),
    );

    // Initialize slide controller for stop button
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Start animations with looping
    _pulseController.repeat(reverse: true);
    _haloController.repeat();
  }

  @override
  void dispose() {
    // Restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose all animation controllers
    _pulseController.dispose();
    _haloController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ACTION METHODS
  // ---------------------------------------------------------------------------

  /// Handles the stop/dismiss alarm action
  void _stopAlarm() {
    if (_isDismissed) return;

    setState(() {
      _isDismissed = true;
    });

    // Stop all animations
    _pulseController.stop();
    _haloController.stop();

    // Provide haptic feedback
    HapticFeedback.heavyImpact();

    // Call the callback and pop the screen
    widget.onStop?.call();
    Navigator.of(context).pop();
  }

  /// Handles the snooze action
  void _snoozeAlarm() {
    if (_isDismissed) return;

    setState(() {
      _isDismissed = true;
    });

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Call the callback and pop the screen
    widget.onSnooze?.call();
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // BUILD METHODS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parse time to show AM/PM format
    final timeParts = widget.alarmTime.split(':');
    String displayTime = widget.alarmTime;
    String amPm = 'AM';

    if (timeParts.length >= 2) {
      int hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = timeParts[1];

      if (hour >= 12) {
        amPm = 'PM';
        if (hour > 12) hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }

      displayTime = '$hour:$minute';
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Subtle gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A2F1A),
                    AppColors.darkBackground,
                  ]
                : [
                    const Color(0xFFE8F5E9),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // MAIN CONTENT AREA (Centered time display with animation)
              // ---------------------------------------------------------------
              Expanded(
                flex: 3,
                child: Center(
                  child: _buildAnimatedTimeDisplay(
                    size: size,
                    displayTime: displayTime,
                    amPm: amPm,
                    isDark: isDark,
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // ACTION BUTTONS AREA (Bottom section)
              // ---------------------------------------------------------------
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stop Alarm button (slide to stop)
                      _buildStopButton(isDark),

                      const SizedBox(height: 16),

                      // Snooze button
                      _buildSnoozeButton(isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the animated time display with pulsing rings
  Widget _buildAnimatedTimeDisplay({
    required Size size,
    required String displayTime,
    required String amPm,
    required bool isDark,
  }) {
    // Calculate ring size based on screen width
    final ringSize = size.width * 0.7;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _haloController]),
      builder: (context, child) {
        return SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding halo effect
              // This creates the visual "ringing" appearance
              Transform.scale(
                scale: _haloAnimation.value,
                child: Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary
                          .withOpacity(_haloOpacityAnimation.value),
                      width: 3,
                    ),
                  ),
                ),
              ),

              // Secondary expanding halo (offset for layered effect)
              Transform.scale(
                scale: _haloAnimation.value * 0.85,
                child: Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary
                          .withOpacity(_haloOpacityAnimation.value * 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Main pulsing ring container
              // This is the primary visual element that pulses gently
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: ringSize * 0.85,
                  height: ringSize * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Soft gradient fill for the ring
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.1),
                      ],
                      stops: const [0.5, 0.8, 1.0],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 4,
                    ),
                  ),
                ),
              ),

              // Inner solid circle
              Container(
                width: ringSize * 0.65,
                height: ringSize * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkCardBackground.withOpacity(0.9)
                      : Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              // Time and label content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Time display with AM/PM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Main time (large, bold)
                      Text(
                        displayTime,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // AM/PM indicator
                      Text(
                        amPm,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Alarm label (title from reminder)
                  Text(
                    widget.alarmLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Repeat type (secondary info)
                  Text(
                    widget.repeatType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the slide-to-stop button
  Widget _buildStopButton(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final buttonHeight = 56.0;
        final thumbSize = 44.0;
        final maxSlide = maxWidth - thumbSize - 12;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _slidePosition += details.delta.dx / maxSlide;
              _slidePosition = _slidePosition.clamp(0.0, 1.0);
            });

            // Trigger stop when fully slid
            if (_slidePosition >= 0.95) {
              _stopAlarm();
            }
          },
          onHorizontalDragEnd: (details) {
            // Reset if not fully slid
            if (_slidePosition < 0.95) {
              setState(() {
                _slidePosition = 0.0;
              });
            }
          },
          child: Container(
            width: maxWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(buttonHeight / 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // "Stop Alarm" label
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stop_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stop Alarm',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sliding thumb
                Positioned(
                  left: 6 + (_slidePosition * maxSlide),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(thumbSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the snooze button
  Widget _buildSnoozeButton(bool isDark) {
    return GestureDetector(
      onTap: _snoozeAlarm,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Snooze',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.snoozeDuration} mins',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
