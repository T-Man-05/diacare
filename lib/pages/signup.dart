import 'package:flutter/material.dart';
import 'date_gen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreen();
}

class _SignupScreen extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'DiaCare',
                style: TextStyle(
                  fontFamily: 'Borel',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 68,
                  height: 1.0,
                  letterSpacing: 0.0,
                  color: Color(0xFF16B8A8),
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
                //height: 520,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Welcome!',
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

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Username',
                          style: TextStyle(
                            fontFamily: 'Inter',           // Font
                            fontWeight: FontWeight.w500,   // Weight (400)
                            fontStyle: FontStyle.normal,   // Style (Regular)
                            fontSize: 18,                  // Size (18px)
                            height: 1.0,                   // Line height (100%)
                            letterSpacing: 0.0,            // Letter spacing (0%)
                            color: Color(0xFF5D5D5D),      // Default black text
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF0E8278), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'choose an @Username',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height:16,),
                      // Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            fontFamily: 'Inter',           // Font
                            fontWeight: FontWeight.w500,   // Weight (400)
                            fontStyle: FontStyle.normal,   // Style (Regular)
                            fontSize: 18,                  // Size (18px)
                            height: 1.0,                   // Line height (100%)
                            letterSpacing: 0.0,            // Letter spacing (0%)
                            color: Color(0xFF5D5D5D),      // Default black text
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF0E8278), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Enter your email',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: TextStyle(
                            fontFamily: 'Inter',           // Font
                            fontWeight: FontWeight.w500,   // Weight (400)
                            fontStyle: FontStyle.normal,   // Style (Regular)
                            fontSize: 18,                  // Size (18px)
                            height: 1.0,                   // Line height (100%)
                            letterSpacing: 0.0,            // Letter spacing (0%)
                            color: Color(0xFF5D5D5D),      // Default black text
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFFD9D9D9), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color(0xFF0E8278), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Enter your password',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DateGenScreen()),
                          );},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16B8A8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontFamily: 'Inter',           // Font
                              fontWeight: FontWeight.w600,   // Weight (600 → Semi Bold)
                              fontStyle: FontStyle.normal,   // Style (Regular)
                              fontSize: 18,                  // Size (18px)
                              height: 1.0,                   // Line height (100%)
                              letterSpacing: 0.0,            // Letter spacing (0%)
                              color: Colors.white,           // Optional, depends on button color
                            ),
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 46),
              const Text(
                ' ',
                style: TextStyle(
                  color: Color(0xFF16B8A8),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF16B8A8),
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
