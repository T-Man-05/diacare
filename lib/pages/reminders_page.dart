import 'package:flutter/material.dart';
import '../widgets/reminder_card_widget.dart';
import '../widgets/reminder_status_dialog.dart';
import '../utils/constants.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool notificationsEnabled = true;

  List<Map<String, dynamic>> reminders = [
    {
      'id': '1',
      'title': 'Check Your Glucose Level',
      'nextTime': '18H00',
      'timeRemaining': 'in 2h6min',
      'isLate': false,
      'isDone': false,
      'icon': Icons.access_time,
    },
    {
      'id': '2',
      'title': 'Drink Water',
      'nextTime': '16H00',
      'timeRemaining': 'in 6min',
      'isLate': false,
      'isDone': true,
      'icon': Icons.check,
    },
    {
      'id': '3',
      'title': 'Take Your Pill',
      'nextTime': '15H00',
      'timeRemaining': '54min late',
      'isLate': true,
      'isDone': false,
      'icon': Icons.info_outline,
    },
    {
      'id': '4',
      'title': 'Check Your Glucose Level',
      'nextTime': '18H00',
      'timeRemaining': 'in 2h6min',
      'isLate': false,
      'isDone': false,
      'icon': Icons.access_time,
    },
    {
      'id': '5',
      'title': 'Drink Water',
      'nextTime': '16H00',
      'timeRemaining': 'in 6min',
      'isLate': false,
      'isDone': true,
      'icon': Icons.check,
    },
    {
      'id': '6',
      'title': 'Take Your Pill',
      'nextTime': '15H00',
      'timeRemaining': '54min late',
      'isLate': true,
      'isDone': false,
      'icon': Icons.info_outline,
    },
  ];

  void _toggleNotifications() {
    setState(() {
      notificationsEnabled = !notificationsEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notificationsEnabled
              ? 'Notifications enabled'
              : 'Notifications disabled',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: notificationsEnabled ? Colors.green : Colors.grey,
      ),
    );
  }

  void _showStatusDialog(String reminderId, String title) {
    showDialog(
      context: context,
      builder: (context) => ReminderStatusDialog(
        title: title,
        onStatusSelected: (status) {
          _handleStatusChange(reminderId, status);
        },
      ),
    );
  }

  void _handleStatusChange(String reminderId, String status) {
    setState(() {
      final index = reminders.indexWhere((r) => r['id'] == reminderId);
      if (index != -1) {
        if (status == 'done') {
          reminders[index]['isDone'] = true;
          reminders[index]['icon'] = Icons.check;
        } else if (status == 'not_done') {
          reminders[index]['isDone'] = false;
          reminders[index]['icon'] = reminders[index]['isLate']
              ? Icons.info_outline
              : Icons.access_time;
        } else if (status == 'later') {
          reminders[index]['isDone'] = false;
        }
      }
    });

    String message = status == 'done'
        ? 'Reminder marked as done'
        : status == 'not_done'
            ? 'Reminder marked as not done'
            : 'Reminder postponed';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Fri, 24 Oct  15:54',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    notificationsEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  onPressed: _toggleNotifications,
                ),
                if (notificationsEnabled)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return ReminderCardWidget(
            title: reminder['title'],
            nextTime: reminder['nextTime'],
            timeRemaining: reminder['timeRemaining'],
            isLate: reminder['isLate'],
            isDone: reminder['isDone'],
            icon: reminder['icon'],
            onTap: () {
              _showStatusDialog(reminder['id'], reminder['title']);
            },
          );
        },
      ),
      // Bottom navigation removed - handled by MainNavigationPage
    );
  }

  // Removed unused _buildNavItem() method
}
