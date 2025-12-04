import 'package:flutter/material.dart';
import '../models/settings_data.dart';
import '../repositories/app_repository.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  final AppRepository repository;

  const EditProfilePage({Key? key, required this.repository}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  SettingsData? _settingsData;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final allData = await widget.repository.getData();
      final settingsJson = allData['settings'] as Map<String, dynamic>;

      setState(() {
        _settingsData = SettingsData.fromJson(settingsJson);
        _fullNameController.text = _settingsData?.fullName ?? 'Charlotte King';
        _usernameController.text =
            _settingsData?.username ?? '@johnkinggraphics';
        _emailController.text =
            _settingsData?.email ?? 'charlotte.king@email.com';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_settingsData != null) {
        _settingsData!.fullName = _fullNameController.text;
        _settingsData!.username = _usernameController.text;
        _settingsData!.email = _emailController.text;

        await widget.repository.updateSettings(_settingsData!.toJson());

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profileUpdated)),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  String? _validateFullName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fullNameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.fullNameMinLength;
    }
    return null;
  }

  String? _validateUsername(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.usernameRequired;
    }
    if (value.trim().length < 3) {
      return l10n.usernameMinLength;
    }
    final usernameRegex = RegExp(r'^@?[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return l10n.usernameInvalid;
    }
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.emailInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.editProfile,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImage(isDark),
                const SizedBox(height: 32),
                _buildTextField(
                  label: l10n.fullName,
                  controller: _fullNameController,
                  isDark: isDark,
                  theme: theme,
                  validator: (value) => _validateFullName(value, l10n),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: l10n.username,
                  controller: _usernameController,
                  isDark: isDark,
                  theme: theme,
                  validator: (value) => _validateUsername(value, l10n),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: l10n.email,
                  controller: _emailController,
                  isDark: isDark,
                  theme: theme,
                  validator: (value) => _validateEmail(value, l10n),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 40),
                _buildSaveButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(bool isDark) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
          child: const Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required ThemeData theme,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                onPressed: () =>
                    _showEditDialog(label, controller, isDark, theme),
              ),
              errorStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          l10n.saveChanges,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(String label, TextEditingController controller,
      bool isDark, ThemeData theme) {
    final tempController = TextEditingController(text: controller.text);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '${l10n.edit} $label',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: TextField(
          controller: tempController,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                controller.text = tempController.text;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.done,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
