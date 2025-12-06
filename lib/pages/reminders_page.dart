import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/reminder_card_widget.dart';
import '../widgets/reminder_status_dialog.dart';
import '../widgets/add_reminder_dialog.dart';
import '../utils/constants.dart';
import '../services/data_service_new.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

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
          final status = reminder['status'] ?? 'pending';
          final isDone = status == 'done' || status == 'completed';
          // Handle null case for is_enabled - default to true if null
          final isEnabledValue = reminder['is_enabled'];
          final bool isEnabled = isEnabledValue == 1 ||
              isEnabledValue == true ||
              isEnabledValue == null;
          final isLate = _isReminderLate(scheduledTime, isDone);

          return {
            'id': reminder['id'].toString(),
            'title': reminder['title'] ?? '',
            'nextTime': _formatTime(scheduledTime),
            'scheduledTime': scheduledTime,
            'timeRemaining': _getTimeRemaining(scheduledTime, isDone),
            'isLate': isLate,
            'isDone': isDone,
            'isEnabled': isEnabled,
            'icon': _getIcon(isDone, isLate),
            'reminderType': reminder['reminder_type'] ?? '',
          };
        }).toList();

        // Sort: enabled first, then by time
        _reminders.sort((a, b) {
          final aEnabled = a['isEnabled'] as bool? ?? true;
          final bEnabled = b['isEnabled'] as bool? ?? true;
          if (aEnabled != bEnabled) {
            return aEnabled ? -1 : 1;
          }
          return (a['scheduledTime'] as String)
              .compareTo(b['scheduledTime'] as String);
        });

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

  Future<void> _onRefresh() async {
    await _loadReminders();
  }

  String _formatTime(String scheduledTime) {
    if (scheduledTime.isEmpty) return '--:--';
    final parts = scheduledTime.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
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
          return '${absDiff.inHours}h ${absDiff.inMinutes % 60}m late';
        }
        return '${absDiff.inMinutes}m late';
      } else {
        if (diff.inHours > 0) {
          return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
        }
        return 'in ${diff.inMinutes}m';
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
    if (isDone) return Icons.check_circle;
    if (isLate) return Icons.warning_amber_rounded;
    return Icons.schedule;
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        onReminderAdded: () {
          _loadReminders();
        },
      ),
    );
  }

  void _showStatusDialog(String reminderId, String title, String time) {
    showDialog(
      context: context,
      builder: (context) => ReminderStatusDialog(
        title: title,
        time: time,
        onStatusSelected: (status) {
          _handleStatusChange(reminderId, status);
        },
      ),
    );
  }

  Future<void> _handleStatusChange(String reminderId, String status) async {
    final l10n = AppLocalizations.of(context);

    try {
      final dataService = DataService.instance;
      await dataService.updateReminderStatus(
        int.parse(reminderId),
        status,
      );

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

  Future<void> _toggleReminderEnabled(
      String reminderId, bool currentState) async {
    try {
      final dataService = DataService.instance;
      await dataService.updateReminder(reminderId, {
        'is_enabled': currentState ? 0 : 1,
      });
      await _loadReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating reminder: $e'),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedReminders() async {
    if (_selectedIds.isEmpty) return;

    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('deleteReminders')),
        content: Text(
            '${l10n.translate('deleteRemindersConfirm')} (${_selectedIds.length})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dataService = DataService.instance;
      for (final id in _selectedIds) {
        await dataService.deleteReminder(int.parse(id));
      }

      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });

      await _loadReminders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('remindersDeleted')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting reminders: $e'),
          backgroundColor: Colors.red,
        ),
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
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now();
    final formattedDate =
        DateFormat('EEEE, d MMMM', l10n.locale.languageCode).format(now);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reminders,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
          ],
        ),
        actions: [
          if (_isSelectionMode && _selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelectedReminders,
            ),
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist,
              color: _isSelectionMode ? Colors.red : AppColors.primary,
            ),
            onPressed: _toggleSelectionMode,
          ),
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: _showAddReminderDialog,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('addRemindersToStayOnTrack'),
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddReminderDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.translate('addReminder')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          return ReminderCardWidget(
            title: reminder['title'],
            nextTime: reminder['nextTime'],
            timeRemaining: reminder['timeRemaining'],
            isLate: reminder['isLate'],
            isDone: reminder['isDone'],
            isEnabled: reminder['isEnabled'],
            icon: reminder['icon'],
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedIds.contains(reminder['id']),
            onTap: () {
              _showStatusDialog(
                reminder['id'],
                reminder['title'],
                reminder['nextTime'],
              );
            },
            onToggleEnabled: () {
              _toggleReminderEnabled(
                reminder['id'],
                reminder['isEnabled'],
              );
            },
            onSelectToggle: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
              }
              _toggleSelection(reminder['id']);
            },
          );
        },
      ),
    );
  }
}
