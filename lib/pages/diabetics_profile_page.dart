import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/settings_data.dart';
import '../blocs/blocs.dart';
import '../services/data_service_new.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class DiabeticsProfilePage extends StatefulWidget {
  const DiabeticsProfilePage({Key? key}) : super(key: key);

  @override
  State<DiabeticsProfilePage> createState() => _DiabeticsProfilePageState();
}

class _DiabeticsProfilePageState extends State<DiabeticsProfilePage> {
  SettingsData? _settingsData;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _minGlucoseController = TextEditingController();
  final TextEditingController _maxGlucoseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _minGlucoseController.dispose();
    _maxGlucoseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final dataService = DataService.instance;
      final settingsJson = await dataService.getSettings();

      setState(() {
        _settingsData = SettingsData.fromJson(settingsJson);
        _minGlucoseController.text =
            _settingsData!.diabeticProfile.minGlucose.toString();
        _maxGlucoseController.text =
            _settingsData!.diabeticProfile.maxGlucose.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading data: $e');
    }
  }

  String? _validateMinGlucose(
      String? value, AppLocalizations l10n, String units) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired;
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return l10n.invalidNumber;
    }
    // Validate based on units (mg/dL: 50-150, mmol/L: 2.8-8.3)
    if (units == 'mg/dL') {
      if (number < 50 || number > 150) {
        return l10n.numberTooLow;
      }
    } else {
      if (number < 2.8 || number > 8.3) {
        return l10n.numberTooLow;
      }
    }
    return null;
  }

  String? _validateMaxGlucose(
      String? value, AppLocalizations l10n, String units) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired;
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return l10n.invalidNumber;
    }
    // Validate based on units (mg/dL: 100-300, mmol/L: 5.6-16.7)
    if (units == 'mg/dL') {
      if (number < 100 || number > 300) {
        return l10n.numberTooHigh;
      }
    } else {
      if (number < 5.6 || number > 16.7) {
        return l10n.numberTooHigh;
      }
    }
    // Check that max > min
    final minValue = double.tryParse(_minGlucoseController.text.trim());
    if (minValue != null && number <= minValue) {
      return l10n.minGreaterThanMax;
    }
    return null;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_settingsData != null) {
        _settingsData!.diabeticProfile.minGlucose =
            int.tryParse(_minGlucoseController.text) ?? 70;
        _settingsData!.diabeticProfile.maxGlucose =
            int.tryParse(_maxGlucoseController.text) ?? 180;

        final dataService = DataService.instance;
        await dataService.updateSettings(_settingsData!.toJson());

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profileUpdated)),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final units = settingsState.units;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: theme.textTheme.bodyLarge?.color),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.diabeticProfile,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSelectionField(
                      label: l10n.diabetesType,
                      value: _settingsData!.diabeticProfile.diabeticType,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _showDiabeticTypeDialog(isDark, theme, l10n),
                    ),
                    const SizedBox(height: 20),
                    _buildSelectionField(
                      label: l10n.treatmentType,
                      value: _settingsData!.diabeticProfile.treatmentType,
                      isDark: isDark,
                      theme: theme,
                      onTap: () =>
                          _showTreatmentTypeDialog(isDark, theme, l10n),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${l10n.targetRange} ($units)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlucoseField(
                            l10n.minimum,
                            _minGlucoseController,
                            isDark,
                            theme,
                            (value) => _validateMinGlucose(value, l10n, units),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGlucoseField(
                            l10n.maximum,
                            _maxGlucoseController,
                            isDark,
                            theme,
                            (value) => _validateMaxGlucose(value, l10n, units),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildSaveButton(l10n),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardBackground
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Icon(
                  Icons.edit,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlucoseField(
    String label,
    TextEditingController controller,
    bool isDark,
    ThemeData theme,
    String? Function(String?)? validator,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          l10n.saveChanges,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDiabeticTypeDialog(
      bool isDark, ThemeData theme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.diabetesType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRadioOption(l10n.type1, l10n.type1, isDark, theme),
            _buildDialogRadioOption(l10n.type2, l10n.type2, isDark, theme),
            _buildDialogRadioOption(
                l10n.gestational, l10n.gestational, isDark, theme),
          ],
        ),
      ),
    );
  }

  void _showTreatmentTypeDialog(
      bool isDark, ThemeData theme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.treatmentType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRadioOption(l10n.diet, l10n.diet, isDark, theme),
            _buildDialogRadioOption(
                l10n.oralMedication, l10n.oralMedication, isDark, theme),
            _buildDialogRadioOption(l10n.insulin, l10n.insulin, isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRadioOption(
      String value, String title, bool isDark, ThemeData theme) {
    final isSelected = (_settingsData!.diabeticProfile.diabeticType == value) ||
        (_settingsData!.diabeticProfile.treatmentType == value);

    return InkWell(
      onTap: () {
        setState(() {
          // Check if this is a diabetic type or treatment type by checking common values
          final diabeticTypes = [
            'Type 1',
            'Type 2',
            'Gestational',
            'النوع الأول',
            'النوع الثاني',
            'سكري الحمل'
          ];
          if (diabeticTypes
              .any((type) => value.contains(type.split(' ').first))) {
            _settingsData!.diabeticProfile.diabeticType = value;
          } else {
            _settingsData!.diabeticProfile.treatmentType = value;
          }
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: null,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
