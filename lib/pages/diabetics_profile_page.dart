import 'package:flutter/material.dart';
import '../models/settings_data.dart';
import '../repositories/app_repository.dart';
import '../utils/constants.dart';

class DiabeticsProfilePage extends StatefulWidget {
  final AppRepository repository;

  const DiabeticsProfilePage({Key? key, required this.repository})
      : super(key: key);

  @override
  State<DiabeticsProfilePage> createState() => _DiabeticsProfilePageState();
}

class _DiabeticsProfilePageState extends State<DiabeticsProfilePage> {
  SettingsData? _settingsData;
  bool _isLoading = true;

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
      final allData = await widget.repository.getData();
      final settingsJson = allData['settings'] as Map<String, dynamic>;

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

  Future<void> _saveChanges() async {
    if (_settingsData != null) {
      _settingsData!.diabeticProfile.minGlucose =
          int.tryParse(_minGlucoseController.text) ?? 70;
      _settingsData!.diabeticProfile.maxGlucose =
          int.tryParse(_maxGlucoseController.text) ?? 180;

      await widget.repository.updateSettings(_settingsData!.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Diabetic profile updated successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Diabetics Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSelectionField(
                label: 'Diabetic Type',
                value: _settingsData!.diabeticProfile.diabeticType,
                onTap: () => _showDiabeticTypeDialog(),
              ),
              const SizedBox(height: 20),
              _buildSelectionField(
                label: 'Treatment Type',
                value: _settingsData!.diabeticProfile.treatmentType,
                onTap: () => _showTreatmentTypeDialog(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Glucose Target Range (mg/dL)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildGlucoseField('Min', _minGlucoseController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGlucoseField('Max', _maxGlucoseController),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.edit,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlucoseField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
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
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDiabeticTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Select Diabetic Type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRadioOption('Type 1', 'Type 1'),
            _buildDialogRadioOption('Type 2', 'Type 2'),
            _buildDialogRadioOption('Gestational', 'Gestational'),
          ],
        ),
      ),
    );
  }

  void _showTreatmentTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Select Treatment Type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogRadioOption('Diet', 'Diet'),
            _buildDialogRadioOption('Pills', 'Pills'),
            _buildDialogRadioOption('Insulin', 'Insulin'),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRadioOption(String value, String title) {
    final isSelected = (_settingsData!.diabeticProfile.diabeticType == value) ||
        (_settingsData!.diabeticProfile.treatmentType == value);

    return InkWell(
      onTap: () {
        setState(() {
          if (['Type 1', 'Type 2', 'Gestational'].contains(value)) {
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
                style: const TextStyle(fontSize: 16),
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
