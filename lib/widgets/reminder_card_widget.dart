// ========================================
// lib/widgets/reminder_card_widget.dart
// ========================================
import 'package:flutter/material.dart';

class ReminderCardWidget extends StatelessWidget {
  final String title;
  final String nextTime;
  final String timeRemaining;
  final bool isLate;
  final bool isDone;
  final IconData icon;
  final VoidCallback? onTap;

  const ReminderCardWidget({
    Key? key,
    required this.title,
    required this.nextTime,
    required this.timeRemaining,
    this.isLate = false,
    this.isDone = false,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLate ? Colors.red.shade100 : Colors.blue.shade100,
            width: isLate ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Next Time: ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        nextTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeRemaining,
                        style: TextStyle(
                          fontSize: 14,
                          color: isLate ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Icon section
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.teal.shade50
                    : isLate
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDone
                    ? Colors.teal
                    : isLate
                        ? Colors.red
                        : Colors.grey.shade600,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
