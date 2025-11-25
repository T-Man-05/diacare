import 'package:flutter/material.dart';
import 'home.dart';


class DiagnosisTreatementScreen extends StatefulWidget {
  const DiagnosisTreatementScreen({super.key});

  @override
  State<DiagnosisTreatementScreen> createState() => _DiagnosisTreatementScreen();
}

class _DiagnosisTreatementScreen extends State<DiagnosisTreatementScreen> {
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatementController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
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
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Welcome!',
                          style: TextStyle(
                            fontFamily: 'Borel',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 42,
                            height: 1.0,
                            color: Color(0xFF5D5D5D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Date of Birth
                      const Text(
                        'Duration of the diagnosis',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          height: 1.0,
                          color: Color(0xFF5D5D5D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _diagnosisController,
                          
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
                            hintText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),


                      const SizedBox(height: 16),

                      // Gender
                      const Text(
                        'Usual treatment type',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          height: 1.0,
                          color: Color(0xFF5D5D5D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _treatementController,
                           
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
                            hintText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MainNavigationPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16B8A8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
