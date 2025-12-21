import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import '../services/data_service_supabase.dart';

/// Dialog for adding health data (glucose, water, pills, activity, carbs, insulin)
class AddDataDialog extends StatefulWidget {
  final String currentUnits; // 'mg/dL' or 'mmol/L'
  final VoidCallback onDataAdded;

  const AddDataDialog({
    Key? key,
    required this.currentUnits,
    required this.onDataAdded,
  }) : super(key: key);

  @override
  State<AddDataDialog> createState() => _AddDataDialogState();
}

class _AddDataDialogState extends State<AddDataDialog> {
  String? _selectedType;
  final _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // For glucose readings
  String _readingType = 'before_meal';

  // Data types with their storage units (always store in these units)
  static const Map<String, Map<String, dynamic>> _dataTypes = {
    'glucose': {
      'storageUnit': 'mg/dL',
      'icon': Icons.bloodtype,
      'color': Color(0xFFE87B3C),
    },
    'water': {
      'storageUnit': 'L',
      'icon': Icons.water_drop,
      'color': Color(0xFF4FC3C3),
    },
    'pills': {
      'storageUnit': 'taken',
      'icon': Icons.medication,
      'color': Color(0xFF6B9EFA),
    },
    'activity': {
      'storageUnit': 'steps',
      'icon': Icons.directions_walk,
      'color': Color(0xFF9B59B6),
    },
    'carbs': {
      'storageUnit': 'g',
      'icon': Icons.restaurant,
      'color': Color(0xFFE74C3C),
    },
    'insulin': {
      'storageUnit': 'units',
      'icon': Icons.vaccines,
      'color': Color(0xFF3498DB),
    },
  };

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _getLocalizedTypeName(String type, AppLocalizations l10n) {
    switch (type) {
      case 'glucose':
        return l10n.glucoseLevel;
      case 'water':
        return l10n.water;
      case 'pills':
        return l10n.pills;
      case 'activity':
        return l10n.activity;
      case 'carbs':
        return l10n.carbs;
      case 'insulin':
        return l10n.insulinCard;
      default:
        return type;
    }
  }

  String _getDisplayUnit(String type) {
    if (type == 'glucose') {
      return widget.currentUnits;
    }
    return _dataTypes[type]!['storageUnit'] as String;
  }

  String _getHintText(String type, AppLocalizations l10n) {
    switch (type) {
      case 'glucose':
        return widget.currentUnits == 'mg/dL' ? '70-180' : '3.9-10.0';
      case 'water':
        return '0.0-5.0';
      case 'pills':
        return '0-10';
      case 'activity':
        return '0-50000';
      case 'carbs':
        return '0-500';
      case 'insulin':
        return '0-100';
      default:
        return '';
    }
  }

  /// Validate that values are within realistic ranges
  String? _validateRange(String type, double value, AppLocalizations l10n) {
    switch (type) {
      case 'glucose':
        // mg/dL range: 20-600, mmol/L range: 1.1-33.3
        if (widget.currentUnits == 'mg/dL') {
          if (value < 20 || value > 600) {
            return 'Glucose must be between 20-600 mg/dL';
          }
        } else {
          if (value < 1.1 || value > 33.3) {
            return 'Glucose must be between 1.1-33.3 mmol/L';
          }
        }
        break;
      case 'water':
        // Max realistic water intake: 10 liters per day
        if (value > 10) {
          return 'Water intake cannot exceed 10 L';
        }
        break;
      case 'pills':
        // Max realistic pills: 20 per entry
        if (value > 20) {
          return 'Pills cannot exceed 20';
        }
        break;
      case 'activity':
        // Max realistic steps: 100,000 per day (ultra marathon level)
        if (value > 100000) {
          return 'Steps cannot exceed 100,000';
        }
        break;
      case 'carbs':
        // Max realistic carbs: 500g per day
        if (value > 500) {
          return 'Carbs cannot exceed 500 g';
        }
        break;
      case 'insulin':
        // Max realistic insulin: 300 units per day (extreme cases)
        if (value > 300) {
          return 'Insulin cannot exceed 300 units';
        }
        break;
    }
    return null;
  }

  /// Convert input value to storage unit
  double _convertToStorageUnit(String type, double inputValue) {
    if (type == 'glucose' && widget.currentUnits == 'mmol/L') {
      // Convert mmol/L to mg/dL (multiply by 18)
      return inputValue * 18.0;
    }
    return inputValue;
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    setState(() => _isLoading = true);

    try {
      final dataService = getIt<DataService>();
      final inputValue = double.parse(_valueController.text);
      final storageValue = _convertToStorageUnit(_selectedType!, inputValue);

      if (_selectedType == 'glucose') {
        // Add glucose reading
        await dataService.addGlucoseReading(
          value: storageValue,
          unit: 'mg/dL', // Always store in mg/dL
          readingType: _readingType,
        );
      } else {
        // Add health card data
        await dataService.updateHealthCard(
          cardType: _selectedType!,
          value: storageValue,
          unit: _dataTypes[_selectedType]!['storageUnit'] as String,
        );
      }

      if (!mounted) return;

      widget.onDataAdded();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
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
                    Text(
                      l10n.translate('addData'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.iconTheme.color),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Data type selection
                Text(
                  l10n.translate('selectType'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Type selection grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dataTypes.entries.map((entry) {
                    final type = entry.key;
                    final data = entry.value;
                    final isSelected = _selectedType == type;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          _valueController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (data['color'] as Color).withOpacity(0.2)
                              : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? data['color'] as Color
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              data['icon'] as IconData,
                              color: data['color'] as Color,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getLocalizedTypeName(type, l10n),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? data['color'] as Color
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_selectedType != null) ...[
                  const SizedBox(height: 20),

                  // Glucose reading type selector
                  if (_selectedType == 'glucose') ...[
                    Text(
                      l10n.translate('readingType'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReadingTypeButton(
                            'before_meal',
                            l10n.beforeMeal,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildReadingTypeButton(
                            'after_meal',
                            l10n.afterMeal,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Value input
                  Text(
                    '${l10n.translate('value')} (${_getDisplayUnit(_selectedType!)})',
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
                    controller: _valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      hintText: _getHintText(_selectedType!, l10n),
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
                      if (value == null || value.isEmpty) {
                        return l10n.translate('pleaseEnterValue');
                      }
                      final number = double.tryParse(value);
                      if (number == null || number < 0) {
                        return l10n.translate('invalidValue');
                      }
                      // Validate realistic ranges for each type
                      final validationError =
                          _validateRange(_selectedType!, number, l10n);
                      if (validationError != null) {
                        return validationError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveData,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingTypeButton(String type, String label, bool isDark) {
    final isSelected = _readingType == type;
    return GestureDetector(
      onTap: () => setState(() => _readingType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}
