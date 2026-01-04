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
              color: AppColors.primary.withOpacity(isDark ? 0.1 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withOpacity(0.15),
              width: 1,
            ),
          ),
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
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 
                      ? AppColors.pillsColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.alarm,
                  color: _currentIndex == 0 
                      ? AppColors.pillsColor 
                      : (isDark ? AppColors.darkTextSecondary : Colors.grey),
                ),
              ),
              label: l10n.reminders,
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 
                      ? AppColors.waterColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: _currentIndex == 1 
                      ? AppColors.waterColor 
                      : (isDark ? AppColors.darkTextSecondary : Colors.grey),
                ),
              ),
              label: l10n.insights,
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home,
                  color: _currentIndex == 2 
                      ? AppColors.primary 
                      : (isDark ? AppColors.darkTextSecondary : Colors.grey),
                ),
              ),
              label: l10n.dashboard,
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 
                      ? AppColors.insulinColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: _currentIndex == 3 
                      ? AppColors.insulinColor 
                      : (isDark ? AppColors.darkTextSecondary : Colors.grey),
                ),
              ),
              label: l10n.chat,
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 4 
                      ? AppColors.carbsColor.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: _currentIndex == 4 
                      ? AppColors.carbsColor 
                      : (isDark ? AppColors.darkTextSecondary : Colors.grey),
                ),
              ),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
