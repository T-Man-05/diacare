import 'package:flutter/material.dart';
import '../widgets/chart_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/carbs_chart.dart';
import '../widgets/activity_chart.dart';
import '../models/chart_data.dart';
import '../utils/constants.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({Key? key}) : super(key: key);

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BloodSugarChart(
                      flag: false,
                      chartData: _bloodSugarData,
                      onSeeDetails: () {
                        // No action needed in insights page
                      },
                    ),
                    const SizedBox(height: 16),
                    const ChartCard(
                      title: 'Carbs',
                      unit: '(calories)',
                      child: CarbsChart(),
                    ),
                    const SizedBox(height: 16),
                    const ChartCard(
                      title: 'Daily Activity',
                      unit: '(km)',
                      child: ActivityChart(),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: _buildBottomNav(),
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
              color: AppColors.primary,
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

  // Removed unused _buildBottomNav() and _buildNavItem() methods
  // Navigation is now handled by MainNavigationPage
}
