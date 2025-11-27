/// ============================================================================
/// SIGNUP SCREEN - User Registration
/// ============================================================================
///
/// This screen allows new users to create an account in DiaCare.
/// Features:
/// - Username, email, and password input fields
/// - Input validation
/// - Navigation to onboarding flow
/// - Centralized string management
/// ============================================================================

import 'package:flutter/material.dart';
import 'date_gen.dart';
import '../utils/constants.dart';
import '../services/data_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreen();
}

class _SignupScreen extends State<SignupScreen> {
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Loading state
  bool _isLoading = false;

  // App strings from centralized data
  Map<String, dynamic>? _strings;

  @override
  void initState() {
    super.initState();
    _loadStrings();
  }

  /// Load centralized strings from data service
  Future<void> _loadStrings() async {
    try {
      final dataService = DataService.instance;
      final strings = await dataService.getAppStrings();
      if (mounted) {
        setState(() {
          _strings = strings;
        });
      }
    } catch (e) {
      debugPrint('Error loading strings: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate username
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return _strings?['validation']?['username_required'] ??
          'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  /// Validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return _strings?['validation']?['email_required'] ?? 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return _strings?['validation']?['email_invalid'] ??
          'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _strings?['validation']?['password_required'] ??
          'Password is required';
    }
    if (value.length < 6) {
      return _strings?['validation']?['password_too_short'] ??
          'Password must be at least 6 characters';
    }
    return null;
  }

  /// Handle signup button press
  Future<void> _handleSignup() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual user registration logic here
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Navigate to onboarding flow
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DateGenScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while strings are loading
    if (_strings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App name
              Text(
                _strings?['app_name'] ?? 'DiaCare',
                style: TextStyle(
                  fontFamily: 'Borel',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 68,
                  height: 1.0,
                  letterSpacing: 0.0,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 46),

              // Card container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(39),
                  color: const Color(0xFFFFFFFD),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 13,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),

                        // Welcome text
                        Center(
                          child: Text(
                            _strings?['welcome'] ?? 'Welcome!',
                            style: TextStyle(
                              fontFamily: 'Borel',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontSize: 42,
                              height: 1.0,
                              color: Color(0XFF5D5D5D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _strings?['signup']?['username_label'] ??
                                'Username',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 18,
                              height: 1.0,
                              letterSpacing: 0.0,
                              color: Color(0xFF5D5D5D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          validator: _validateUsername,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.primaryDark, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: _strings?['signup']?['username_hint'] ??
                                'choose an @Username',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _strings?['signup']?['email_label'] ??
                                'Email Address',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 18,
                              height: 1.0,
                              letterSpacing: 0.0,
                              color: Color(0xFF5D5D5D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.primaryDark, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: _strings?['signup']?['email_hint'] ??
                                'Enter your email',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _strings?['signup']?['password_label'] ??
                                'Password',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontSize: 18,
                              height: 1.0,
                              letterSpacing: 0.0,
                              color: Color(0xFF5D5D5D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: AppColors.primaryDark, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: _strings?['signup']?['password_hint'] ??
                                'Enter your password',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),

                        const SizedBox(height: 64),

                        // Signup button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _strings?['signup']?['signup_button'] ??
                                        'Sign up',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.normal,
                                      fontSize: 18,
                                      height: 1.0,
                                      letterSpacing: 0.0,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 46),
              const Text(
                ' ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
