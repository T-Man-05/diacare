import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import '../services/data_service_supabase.dart';

/// Dialog for adding a new reminder
class AddReminderDialog extends StatefulWidget {
  final VoidCallback onReminderAdded;

  const AddReminderDialog({
    Key? key,
    required this.onReminderAdded,
  }) : super(key: key);

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // All days by default
  bool _isLoading = false;
  String _selectedType = 'custom';

  // Predefined reminder types
  static const List<Map<String, dynamic>> _reminderTypes = [
    {'id': 'glucose', 'icon': Icons.bloodtype, 'color': Color(0xFFE87B3C)},
    {'id': 'water', 'icon': Icons.water_drop, 'color': Color(0xFF4FC3C3)},
    {'id': 'pills', 'icon': Icons.medication, 'color': Color(0xFF6B9EFA)},
    {
      'id': 'activity',
      'icon': Icons.directions_walk,
      'color': Color(0xFF9B59B6)
    },
    {'id': 'meal', 'icon': Icons.restaurant, 'color': Color(0xFFE74C3C)},
    {
      'id': 'custom',
      'icon': Icons.edit_notifications,
      'color': AppColors.primary
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _getLocalizedTypeName(String type, AppLocalizations l10n) {
    switch (type) {
      case 'glucose':
        return l10n.checkGlucose;
      case 'water':
        return l10n.drinkWater;
      case 'pills':
        return l10n.takePill;
      case 'activity':
        return l10n.activity;
      case 'meal':
        return l10n.translate('meal');
      case 'custom':
        return l10n.translate('custom');
      default:
        return type;
    }
  }

  String _getDayName(int day, AppLocalizations l10n) {
    switch (day) {
      case 1:
        return l10n.dayMon;
      case 2:
        return l10n.dayTue;
      case 3:
        return l10n.dayWed;
      case 4:
        return l10n.dayThu;
      case 5:
        return l10n.dayFri;
      case 6:
        return l10n.daySat;
      case 7:
        return l10n.daySun;
      default:
        return '';
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getRecurrencePattern() {
    if (_selectedDays.length == 7) return 'daily';
    return _selectedDays.map((d) => d.toString()).join(',');
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dataService = getIt<DataService>();
      final l10n = AppLocalizations.of(context);

      // Get title - either from preset type or custom input
      String title;
      if (_selectedType != 'custom') {
        title = _getLocalizedTypeName(_selectedType, l10n);
      } else {
        title = _titleController.text.trim();
      }

      await dataService.addReminder(
        title: title,
        reminderType: _selectedType,
        scheduledTime: _formatTimeOfDay(_selectedTime),
        isRecurring: _selectedDays.length < 7,
        recurrencePattern: _getRecurrencePattern(),
      );

      if (!mounted) return;

      widget.onReminderAdded();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('reminderAdded')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.translate('addReminder'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.iconTheme.color),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reminder type selection
                  Text(
                    l10n.translate('reminderType'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Type selection grid - responsive
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reminderTypes.map((type) {
                      final typeId = type['id'] as String;
                      final isSelected = _selectedType == typeId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = typeId;
                            if (typeId != 'custom') {
                              _titleController.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (type['color'] as Color).withOpacity(0.2)
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? type['color'] as Color
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                color: type['color'] as Color,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _getLocalizedTypeName(typeId, l10n),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? type['color'] as Color
                                        : theme.textTheme.bodyMedium?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Custom title input (only if custom type is selected)
                  if (_selectedType == 'custom') ...[
                    const SizedBox(height: 20),
                    Text(
                      l10n.translate('reminderTitle'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: l10n.translate('enterReminderTitle'),
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      validator: (value) {
                        if (_selectedType == 'custom' &&
                            (value == null || value.trim().isEmpty)) {
                          return l10n.translate('pleaseEnterTitle');
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Time picker
                  Text(
                    l10n.translate('time'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Days selection
                  Text(
                    l10n.translate('repeatOn'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                      final isSelected = _selectedDays.contains(day);
                      final dayName = _getDayName(day, l10n);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected && _selectedDays.length > 1) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.translate('add'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
