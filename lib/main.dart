import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/reminders_page.dart';
import 'pages/insights_page.dart';
import 'pages/chat_page.dart';
import 'repositories/local_demo_repository.dart';

void main() {
  runApp(const DiabeticMonitoringApp());
}

class DiabeticMonitoringApp extends StatelessWidget {
  const DiabeticMonitoringApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetic Monitoring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'SF Pro',
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 2; // Start at Home (Dashboard)
  final repository = LocalDemoRepository();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const RemindersPage(), // Index 0 - Alarm icon
      const InsightsPage(), // Index 1 - Bar chart icon
      DashboardPage(repository: repository), // Index 2 - Home icon
      const ChatPage(), // Index 3 - Chat icon
      MyProfilePage(repository: repository), // Index 4 - Profile icon
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
