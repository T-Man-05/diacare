import 'package:flutter/material.dart';
import '../widgets/reminder_card_widget.dart';
import '../widgets/reminder_status_dialog.dart';
import 'insights_page.dart';
import '../utils/constants.dart';
class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  int _selectedIndex = 0;
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

  void _onNavItemTapped(int index) {
    if (index == 1) {
      // Navigate to Insights screen when Charts icon is tapped
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InsightsPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
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
      // bottomNavigationBar: Container(
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.grey.withOpacity(0.2),
      //         spreadRadius: 1,
      //         blurRadius: 10,
      //         offset: const Offset(0, -2),
      //       ),
      //     ],
      //   ),
      //   child: SafeArea(
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceAround,
      //         children: [
      //           _buildNavItem(Icons.notifications_outlined, 0),
      //           _buildNavItem(Icons.bar_chart, 1),
      //           _buildNavItem(Icons.home_outlined, 2),
      //           _buildNavItem(Icons.chat_bubble_outline, 3),
      //           _buildNavItem(Icons.person_outline, 4),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => _onNavItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected ? Colors.teal : Colors.grey.shade400,
        size: 28,
      ),
    );
  }
}
