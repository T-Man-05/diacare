import 'package:flutter/material.dart';
import '../models/settings_data.dart';
import '../repositories/app_repository.dart';
import '../utils/constants.dart';

/// Settings Page - User profile and app settings
class SettingsPage extends StatefulWidget {
  final AppRepository repository;

  const SettingsPage({Key? key, required this.repository}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsData? _settingsData;
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

      // Extract settings data
      final settingsJson = allData['settings'] as Map<String, dynamic>;

      setState(() {
        _settingsData = SettingsData.fromJson(settingsJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading settings data: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_settingsData != null) {
      await widget.repository.updateSettings(_settingsData!.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_settingsData == null) {
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
              _buildSectionHeader('General'),
              const SizedBox(height: 16),
              _buildGeneralSection(),
              const SizedBox(height: AppSpacing.sectionSpacing),
              // _buildPremiumCard(),
              const SizedBox(height: AppSpacing.sectionSpacing),
              _buildSectionHeader('Account'),
              const SizedBox(height: 16),
              _buildAccountSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTextStyles.sectionHeader);
  }

  Widget _buildGeneralSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Personal details',
            onTap: _showPersonalDetailsDialog,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            trailing: 'English',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.star,
            title: 'Rate us',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Terms Of Use',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.feedback,
            title: 'Feedback',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  
  Widget _buildAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.delete,
            title: 'Delete account',
            iconColor: Colors.red,
            onTap: _showDeleteAccountDialog,
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: AppColors.primary,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? trailing,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
      ),
      title: Text(title, style: AppTextStyles.cardTitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 72);

  void _showPersonalDetailsDialog() {
    final emailController = TextEditingController(text: _settingsData!.email);
    final passwordController =
        TextEditingController(text: _settingsData!.password);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.contains('@') &&
                  passwordController.text.isNotEmpty) {
                setState(() {
                  _settingsData!.email = emailController.text;
                  _settingsData!.password = passwordController.text;
                });
                _saveSettings();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid email and password'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
