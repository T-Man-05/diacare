import 'package:flutter/material.dart';
import 'height_weight.dart';
import '../utils/constants.dart';

class DateGenScreen extends StatefulWidget {
  const DateGenScreen({super.key});

  @override
  State<DateGenScreen> createState() => _DateGenScreen();
}

class _DateGenScreen extends State<DateGenScreen> {
  final TextEditingController _dateController = TextEditingController();

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

                      // Date of Birth
                      Text(
                        'Date of birth',
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
                          controller: _dateController,
                          readOnly: true,
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
                            hintText: 'Select your date of birth',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme(
                                      brightness: isDark ? Brightness.dark : Brightness.light,
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      secondary: AppColors.primary,
                                      onSecondary: Colors.white,
                                      error: Colors.red,
                                      onError: Colors.white,
                                      background: theme.scaffoldBackgroundColor,
                                      onBackground: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      surface: theme.cardColor,
                                      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _dateController.text =
                                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Gender
                      Text(
                        'Gender',
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
                            'Select your gender',
                            style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female')),
                            DropdownMenuItem(
                                value: 'Mechanic', child: Text('Mechanic')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {},
                        ),
                      ),

                      SizedBox(height: isPortrait ? 64 : 32),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const HeightWeightScreen()),
                            );
                          },
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
