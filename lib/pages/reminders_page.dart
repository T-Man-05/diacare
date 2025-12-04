import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/reminder_card_widget.dart';
import '../widgets/reminder_status_dialog.dart';
import '../utils/constants.dart';
import '../services/data_service_new.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool notificationsEnabled = true;
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final dataService = DataService.instance;
      final remindersData = await dataService.getReminders();

      setState(() {
        _reminders = remindersData.map((r) {
          final reminder = r as Map<String, dynamic>;
          final scheduledTime = reminder['scheduled_time'] ?? '';
          final isDone = reminder['is_completed'] == 1;
          final isLate = _isReminderLate(scheduledTime, isDone);

          return {
            'id': reminder['id'].toString(),
            'title': reminder['title'] ?? '',
            'nextTime': _formatTime(scheduledTime),
            'timeRemaining': _getTimeRemaining(scheduledTime, isDone),
            'isLate': isLate,
            'isDone': isDone,
            'icon': _getIcon(isDone, isLate),
            'reminderType': reminder['reminder_type'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      setState(() {
        _reminders = [];
        _isLoading = false;
      });
    }
  }

  String _formatTime(String scheduledTime) {
    if (scheduledTime.isEmpty) return '--:--';
    // Format "HH:mm" to "HHH00" display format
    final parts = scheduledTime.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}H${parts[1]}';
    }
    return scheduledTime;
  }

  String _getTimeRemaining(String scheduledTime, bool isDone) {
    if (isDone) return 'Done';
    if (scheduledTime.isEmpty) return '';

    try {
      final parts = scheduledTime.split(':');
      if (parts.length < 2) return '';

      final now = DateTime.now();
      final scheduledHour = int.parse(parts[0]);
      final scheduledMinute = int.parse(parts[1]);

      final scheduled = DateTime(
          now.year, now.month, now.day, scheduledHour, scheduledMinute);
      final diff = scheduled.difference(now);

      if (diff.isNegative) {
        final absDiff = diff.abs();
        if (absDiff.inHours > 0) {
          return '${absDiff.inHours}h${absDiff.inMinutes % 60}min late';
        }
        return '${absDiff.inMinutes}min late';
      } else {
        if (diff.inHours > 0) {
          return 'in ${diff.inHours}h${diff.inMinutes % 60}min';
        }
        return 'in ${diff.inMinutes}min';
      }
    } catch (e) {
      return '';
    }
  }

  bool _isReminderLate(String scheduledTime, bool isDone) {
    if (isDone || scheduledTime.isEmpty) return false;

    try {
      final parts = scheduledTime.split(':');
      if (parts.length < 2) return false;

      final now = DateTime.now();
      final scheduledHour = int.parse(parts[0]);
      final scheduledMinute = int.parse(parts[1]);

      final scheduled = DateTime(
          now.year, now.month, now.day, scheduledHour, scheduledMinute);
      return now.isAfter(scheduled);
    } catch (e) {
      return false;
    }
  }

  IconData _getIcon(bool isDone, bool isLate) {
    if (isDone) return Icons.check;
    if (isLate) return Icons.info_outline;
    return Icons.access_time;
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

  void _handleStatusChange(String reminderId, String status) async {
    final l10n = AppLocalizations.of(context);

    try {
      final dataService = DataService.instance;
      await dataService.updateReminderStatus(
        int.parse(reminderId),
        status,
      );

      // Reload reminders to reflect the change
      await _loadReminders();

      if (!mounted) return;

      String message = status == 'done'
          ? l10n.markedDone
          : status == 'not_done'
              ? l10n.markedNotDone
              : l10n.reminderPostponed;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating reminder: $e'),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.background;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final notifBorderColor =
        isDark ? AppColors.darkCardBackground : Colors.white;
    final l10n = AppLocalizations.of(context);

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
      body: _buildBody(l10n, textPrimary, textSecondary),
    );
  }

  Widget _buildBody(
      AppLocalizations l10n, Color textPrimary, Color textSecondary) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noReminders,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add reminders to stay on track',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
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
    );
  }
}
