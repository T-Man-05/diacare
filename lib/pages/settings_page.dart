import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/settings_data.dart';
import '../repositories/app_repository.dart';
import '../utils/constants.dart';
import '../blocs/blocs.dart';
import '../l10n/app_localizations.dart';
import 'edit_profile_page.dart';
import 'diabetics_profile_page.dart';
import 'login.dart';

class MyProfilePage extends StatefulWidget {
  final AppRepository repository;

  const MyProfilePage({Key? key, required this.repository}) : super(key: key);

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  SettingsData? _settingsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allData = await widget.repository.getData();
      final settingsJson = allData['settings'] as Map<String, dynamic>;

      setState(() {
        _settingsData = SettingsData.fromJson(settingsJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_settingsData != null) {
      await widget.repository.updateSettings(_settingsData!.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_settingsData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: Text(l10n.error)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.myProfile,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              _buildProfileHeader(isDark),
              const SizedBox(height: 24),
              _buildMainMenuSection(isDark, l10n),
              const SizedBox(height: 24),
              _buildAccountActionsSection(isDark, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: _settingsData?.profileImageUrl != null
                  ? NetworkImage(_settingsData!.profileImageUrl!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: _settingsData?.profileImageUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _settingsData?.fullName ?? 'Charlotte King',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _settingsData?.username ?? '@johnkinggraphics',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenuSection(bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: l10n.editProfile,
            isDark: isDark,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfilePage(repository: widget.repository),
                ),
              );
              _loadData();
            },
          ),
          _buildDivider(isDark),
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: l10n.diabeticProfile,
            isDark: isDark,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DiabeticsProfilePage(repository: widget.repository),
                ),
              );
              _loadData();
            },
          ),
          _buildDivider(isDark),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: l10n.settings,
            isDark: isDark,
            onTap: () {
              _showSettingsBottomSheet();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsSection(bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.delete_outline,
            title: l10n.deleteAccount,
            iconColor: Colors.red,
            textColor: Colors.red,
            isDark: isDark,
            onTap: _showDeleteAccountDialog,
          ),
          _buildDivider(isDark),
          _buildMenuItem(
            icon: Icons.logout,
            title: l10n.logout,
            iconColor: AppColors.primary,
            textColor: AppColors.primary,
            isDark: isDark,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ??
              (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) => Divider(
        height: 1,
        indent: 72,
        color: isDark ? Colors.grey[700] : Colors.grey[300],
      );

  void _showSettingsBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.settings,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(l10n.theme, isDark),
                      const SizedBox(height: 12),
                      _buildThemeSection(isDark, l10n),
                      const SizedBox(height: 24),
                      _buildSectionHeader(l10n.language, isDark),
                      const SizedBox(height: 12),
                      _buildLanguageSection(isDark, l10n),
                      const SizedBox(height: 24),
                      _buildSectionHeader(l10n.notifications, isDark),
                      const SizedBox(height: 12),
                      _buildNotificationsSection(isDark, l10n),
                      const SizedBox(height: 24),
                      _buildSectionHeader(l10n.glucoseUnits, isDark),
                      const SizedBox(height: 12),
                      _buildUnitsSection(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildThemeSection(bool isDark, AppLocalizations l10n) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final settingsCubit = context.read<SettingsCubit>();
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildThemeRadioTile(
                icon: Icons.wb_sunny_outlined,
                title: l10n.themeLight,
                value: ThemeMode.light,
                groupValue: settingsState.themeMode,
                isDark: isDark,
                onChanged: (value) {
                  settingsCubit.setThemeMode(value!);
                },
              ),
              _buildSettingsDivider(isDark),
              _buildThemeRadioTile(
                icon: Icons.nightlight_round,
                title: l10n.themeDark,
                value: ThemeMode.dark,
                groupValue: settingsState.themeMode,
                isDark: isDark,
                onChanged: (value) {
                  settingsCubit.setThemeMode(value!);
                },
              ),
              _buildSettingsDivider(isDark),
              _buildThemeRadioTile(
                icon: Icons.computer,
                title: l10n.themeSystem,
                value: ThemeMode.system,
                groupValue: settingsState.themeMode,
                isDark: isDark,
                onChanged: (value) {
                  settingsCubit.setThemeMode(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageSection(bool isDark, AppLocalizations l10n) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        final localeCubit = context.read<LocaleCubit>();
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildLanguageRadioTile(
                title: l10n.languageEn,
                value: 'en',
                groupValue: localeState.languageCode,
                isDark: isDark,
                onChanged: (value) {
                  localeCubit.setLocale(value!);
                },
              ),
              _buildSettingsDivider(isDark),
              _buildLanguageRadioTile(
                title: l10n.languageFr,
                value: 'fr',
                groupValue: localeState.languageCode,
                isDark: isDark,
                onChanged: (value) {
                  localeCubit.setLocale(value!);
                },
              ),
              _buildSettingsDivider(isDark),
              _buildLanguageRadioTile(
                title: l10n.languageAr,
                value: 'ar',
                groupValue: localeState.languageCode,
                isDark: isDark,
                onChanged: (value) {
                  localeCubit.setLocale(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSection(bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.enableNotifications,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: _settingsData!.preferences.notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _settingsData!.preferences.notificationsEnabled = value;
              });
              _saveSettings();
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsSection(bool isDark) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final settingsCubit = context.read<SettingsCubit>();
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildRadioTile(
                title: 'mg/dL',
                value: 'mg/dL',
                groupValue: settingsState.units,
                isDark: isDark,
                onChanged: (value) {
                  settingsCubit.setUnits(value!);
                },
                showIcon: false,
              ),
              _buildSettingsDivider(isDark),
              _buildRadioTile(
                title: 'mmol/L',
                value: 'mmol/L',
                groupValue: settingsState.units,
                isDark: isDark,
                onChanged: (value) {
                  settingsCubit.setUnits(value!);
                },
                showIcon: false,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeRadioTile({
    required IconData icon,
    required String title,
    required ThemeMode value,
    required ThemeMode groupValue,
    required bool isDark,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    IconData? icon,
    required String title,
    required String value,
    required String groupValue,
    required bool isDark,
    required ValueChanged<String?> onChanged,
    bool showIcon = true,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (showIcon && icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsDivider(bool isDark) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: isDark ? Colors.grey[700] : Colors.grey[300],
      );

  void _showDeleteAccountDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.deleteAccount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.deleteAccountConfirm,
          style: TextStyle(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.accountDeleted)),
              );
              // Navigate to login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              l10n.confirm,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.logout,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.logoutConfirm,
          style: TextStyle(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.loggedOut)),
              );
              // Navigate to login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              l10n.confirm,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
