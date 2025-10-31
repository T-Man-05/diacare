import 'package:flutter/material.dart';
import '../widgets/chart_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/carbs_chart.dart';
import '../widgets/activity_chart.dart';
import '../models/chart_data.dart';
import 'reminders_page.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({Key? key}) : super(key: key);

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _selectedIndex = 1;
  late final ChartData _bloodSugarData;

  @override
  void initState() {
    super.initState();
    _bloodSugarData = ChartData(
      title: 'Blood Sugar',
      data: {
        'before_meal': [120, 110, 130, 125, 140, 100, 105],
        'after_meal': [160, 150, 140, 130, 145, 135, 120],
      },
      days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Navigate to Reminders screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RemindersPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ChartCard(
                      title: 'Blood Sugar',
                      unit: '(mg/dl)',
                      child: BloodSugarChart(
                        chartData: _bloodSugarData,
                        onSeeDetails: () {
                          // No action needed in insights page
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      title: 'Carbs',
                      unit: '(calories)',
                      child: const CarbsChart(),
                    ),
                    const SizedBox(height: 16),
                    ChartCard(
                      title: 'Daily Activity',
                      unit: '(km)',
                      child: const ActivityChart(),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3C3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.notifications_outlined, 0),
              _buildNavItem(Icons.bar_chart, 1),
              _buildNavItem(Icons.home_outlined, 2),
              _buildNavItem(Icons.chat_bubble_outline, 3),
              _buildNavItem(Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => _onNavItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF4FC3C3) : Colors.grey.shade400,
        size: 28,
      ),
    );
  }
}
