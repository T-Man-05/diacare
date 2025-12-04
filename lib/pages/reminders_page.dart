import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
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

  List<Map<String, dynamic>> _getReminders(AppLocalizations l10n) {
    return [
      {
        'id': '1',
        'title': l10n.checkGlucose,
        'nextTime': '18H00',
        'timeRemaining': 'in 2h6min',
        'isLate': false,
        'isDone': false,
        'icon': Icons.access_time,
      },
      {
        'id': '2',
        'title': l10n.drinkWater,
        'nextTime': '16H00',
        'timeRemaining': 'in 6min',
        'isLate': false,
        'isDone': true,
        'icon': Icons.check,
      },
      {
        'id': '3',
        'title': l10n.takePill,
        'nextTime': '15H00',
        'timeRemaining': '54min late',
        'isLate': true,
        'isDone': false,
        'icon': Icons.info_outline,
      },
      {
        'id': '4',
        'title': l10n.checkGlucose,
        'nextTime': '18H00',
        'timeRemaining': 'in 2h6min',
        'isLate': false,
        'isDone': false,
        'icon': Icons.access_time,
      },
      {
        'id': '5',
        'title': l10n.drinkWater,
        'nextTime': '16H00',
        'timeRemaining': 'in 6min',
        'isLate': false,
        'isDone': true,
        'icon': Icons.check,
      },
      {
        'id': '6',
        'title': l10n.takePill,
        'nextTime': '15H00',
        'timeRemaining': '54min late',
        'isLate': true,
        'isDone': false,
        'icon': Icons.info_outline,
      },
    ];
  }

  void _toggleNotifications(AppLocalizations l10n) {
    setState(() {
      notificationsEnabled = !notificationsEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notificationsEnabled
              ? l10n.notificationsEnabled
              : l10n.notificationsDisabled,
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
    final l10n = AppLocalizations.of(context);

    String message = status == 'done'
        ? l10n.markedDone
        : status == 'not_done'
            ? l10n.markedNotDone
            : l10n.reminderPostponed;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final notifBorderColor =
        isDark ? AppColors.darkCardBackground : Colors.white;
    final l10n = AppLocalizations.of(context);

    final reminders = _getReminders(l10n);
    final now = DateTime.now();
    final formattedDate =
        DateFormat('E, d MMM  HH:mm', l10n.locale.languageCode).format(now);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reminders,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 14, color: textPrimary),
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
                  onPressed: () => _toggleNotifications(l10n),
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
                        border: Border.all(color: notifBorderColor, width: 2),
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
    );
  }
}
