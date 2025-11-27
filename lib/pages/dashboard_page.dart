import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../repositories/app_repository.dart';
import '../widgets/info_card.dart';
import '../widgets/blood_sugar_chart.dart';
import '../utils/constants.dart';
import 'insights_page.dart';

/// Dashboard Page - Main screen showing health metrics
class DashboardPage extends StatefulWidget {
  final AppRepository repository;

  const DashboardPage({Key? key, required this.repository}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data using single getData() function from repository
  Future<void> _loadData() async {
    try {
      // Call single getData() function
      final allData = await widget.repository.getData();

      // Extract dashboard data
      final dashboardJson = allData['dashboard'] as Map<String, dynamic>;

      setState(() {
        _dashboardData = DashboardData.fromJson(dashboardJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dashboardData == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading data')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildGlucoseCard(),
              const SizedBox(height: 16),
              _buildReminderCard(),
              const SizedBox(height: 20),
              _buildHealthCardsGrid(),
              const SizedBox(height: AppSpacing.sectionSpacing),
              BloodSugarChart(
                flag: true,
                chartData: _dashboardData!.chart,
                onSeeDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsightsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_dashboardData!.greeting, style: AppTextStyles.greeting),
        Row(
          children: [
            _buildIconButton(Icons.add),
            const SizedBox(width: 12),
            _buildIconButton(Icons.notifications),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildGlucoseCard() {
    final glucose = _dashboardData!.glucose;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Glucose', style: AppTextStyles.cardTitle),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${glucose.value} ',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: glucose.unit,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                glucose.status,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Reminder',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _dashboardData!.reminder,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Text(
                '15:34:12',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCardsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.gridSpacing,
        mainAxisSpacing: AppSpacing.gridSpacing,
        childAspectRatio: 2,
      ),
      itemCount: _dashboardData!.healthCards.length,
      itemBuilder: (context, index) {
        return InfoCard(healthCard: _dashboardData!.healthCards[index]);
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
