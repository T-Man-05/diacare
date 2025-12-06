import 'package:flutter/material.dart';
import 'diabetes_type.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class HeightWeightScreen extends StatefulWidget {
  const HeightWeightScreen({super.key});

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreen();
}

class _HeightWeightScreen extends State<HeightWeightScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _validationError;

  void _validateAndContinue() {
    final localizations = AppLocalizations.of(context);
    setState(() => _validationError = null);
    
    if (_heightController.text.isEmpty) {
      setState(() => _validationError = localizations.translate('onboarding.validation_height_required'));
      return;
    }

    // Validate height is a positive number
    final heightValue = double.tryParse(_heightController.text);
    if (heightValue == null || heightValue <= 0) {
      setState(() => _validationError = localizations.translate('onboarding.validation_height_invalid'));
      return;
    }
    
    if (_weightController.text.isEmpty) {
      setState(() => _validationError = localizations.translate('onboarding.validation_weight_required'));
      return;
    }

    // Validate weight is a positive number
    final weightValue = double.tryParse(_weightController.text);
    if (weightValue == null || weightValue <= 0) {
      setState(() => _validationError = localizations.translate('onboarding.validation_weight_invalid'));
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiabetesTypeScreen()),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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

                      // Height
                      Text(
                        AppLocalizations.of(context).translate('onboarding.height'),
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
                        child: TextField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                            hintText: AppLocalizations.of(context).translate('onboarding.height_hint'),
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Weight
                      Text(
                        AppLocalizations.of(context).translate('onboarding.weight'),
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
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                            hintText: AppLocalizations.of(context).translate('onboarding.weight_hint'),
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
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
