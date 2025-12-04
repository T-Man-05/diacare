import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';
import 'reminders_page.dart';
import 'insights_page.dart';
import 'chat_page.dart';

import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 2; // Start at Home (Dashboard)

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      RemindersPage(), // Index 0 - Alarm icon
      InsightsPage(), // Index 1 - Bar chart icon
      DashboardPage(), // Index 2 - Home icon
      ChatPage(), // Index 3 - Chat icon
      MyProfilePage(), // Index 4 - Profile icon
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
          backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor:
              isDark ? AppColors.darkTextSecondary : Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.alarm),
              label: l10n.reminders,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart),
              label: l10n.insights,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              label: l10n.chat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
