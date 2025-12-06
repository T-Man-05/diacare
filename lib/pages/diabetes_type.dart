import 'package:flutter/material.dart';
import 'diagnosis_treateement.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class DiabetesTypeScreen extends StatefulWidget {
  const DiabetesTypeScreen({super.key});

  @override
  State<DiabetesTypeScreen> createState() => _DiabetesTypeScreen();
}

class _DiabetesTypeScreen extends State<DiabetesTypeScreen> {
  String? _selectedDiabetesType;
  String? _selectedUnit;
  String? _validationError;

  void _validateAndContinue() {
    final localizations = AppLocalizations.of(context);
    setState(() => _validationError = null);
    
    if (_selectedDiabetesType == null || _selectedDiabetesType!.isEmpty) {
      setState(() => _validationError = localizations.translate('onboarding.validation_diabetes_type_required'));
      return;
    }
    
    if (_selectedUnit == null || _selectedUnit!.isEmpty) {
      setState(() => _validationError = localizations.translate('onboarding.validation_unit_required'));
      return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const DiagnosisTreatementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    // Responsive sizing
    final horizontalPadding = screenWidth < 600 ? 20.0 : 32.0;
    final verticalPadding = screenHeight < 800 ? 40.0 : 64.0;
    final titleFontSize = screenWidth < 600 ? 48.0 : 68.0;
    final labelFontSize = screenWidth < 600 ? 14.0 : 18.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'DiaCare',
                style: TextStyle(
                  fontFamily: 'Borel',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: titleFontSize,
                  height: 1.0,
                  letterSpacing: 0.0,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: isPortrait ? 46 : 24),

              // Card container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(39),
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : const Color(0x40000000),
                      blurRadius: 13,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isPortrait ? 32 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Welcome!',
                          style: TextStyle(
                            fontFamily: 'Borel',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: isPortrait ? 42 : 32,
                            height: 1.0,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: isPortrait ? 32 : 20),

                      // Type of diabetes
                      Text(
                        AppLocalizations.of(context).translate('onboarding.diabetes_type'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: labelFontSize,
                          height: 1.0,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                        SizedBox(
                        height: 42,
                        child: DropdownButtonFormField<String>(
                          value: _selectedDiabetesType,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : const Color(0xFFD9D9D9),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                          hint: Text(
                            AppLocalizations.of(context).translate('onboarding.diabetes_type_hint'),
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'type1',
                                child: Text(AppLocalizations.of(context).translate('onboarding.diabetes_type_1'))),
                            DropdownMenuItem(
                                value: 'type2',
                                child: Text(AppLocalizations.of(context).translate('onboarding.diabetes_type_2'))),
                            DropdownMenuItem(
                                value: 'gestational',
                                child: Text(AppLocalizations.of(context).translate('onboarding.diabetes_gestational'))),
                            DropdownMenuItem(
                                value: 'monogenic',
                                child: Text(AppLocalizations.of(context).translate('onboarding.diabetes_monogenic'))),
                            DropdownMenuItem(
                                value: 'secondary',
                                child: Text(AppLocalizations.of(context).translate('onboarding.diabetes_secondary'))),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedDiabetesType = value);
                          },
                        ),
                      ),                      const SizedBox(height: 16),

                      // Unit preferences
                      Text(
                        AppLocalizations.of(context).translate('onboarding.unit_preferences'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: labelFontSize,
                          height: 1.0,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: isDark ? Colors.grey[700]! : const Color(0xFFD9D9D9),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                          hint: Text(
                            AppLocalizations.of(context).translate('onboarding.unit_preferences_hint'),
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'mg_dl',
                                child: Text(AppLocalizations.of(context).translate('onboarding.mg_dl'))),
                            DropdownMenuItem(
                                value: 'mmol_l',
                                child: Text(AppLocalizations.of(context).translate('onboarding.mmol_l'))),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedUnit = value);
                          },
                        ),
                      ),

                      SizedBox(height: isPortrait ? 64 : 32),

                      // Validation error message
                      if (_validationError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _validateAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isPortrait ? 46 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
