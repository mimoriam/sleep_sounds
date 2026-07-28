import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/permission_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_themes.dart';
import '../profile/widgets/premium.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemes.paddingScreen,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Appearance
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 12),
              _buildCardContainer(context, [
                _buildRadioTile<ThemeMode>(
                  context: context,
                  title: 'Dark Theme (Recommended)',
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    if (val != null) settings.setThemeMode(val);
                  },
                ),
                _buildDivider(context),
                _buildRadioTile<ThemeMode>(
                  context: context,
                  title: 'Light Theme',
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    if (val != null) settings.setThemeMode(val);
                  },
                ),
                _buildDivider(context),
                _buildRadioTile<ThemeMode>(
                  context: context,
                  title: 'System Default',
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    if (val != null) settings.setThemeMode(val);
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Section 2: Playback & Timer Defaults
              _buildSectionHeader('Playback'),
              const SizedBox(height: 12),
              _buildCardContainer(context, [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Sleep Timer',
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-select timer when launching a sound',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [null, 15, 30, 45, 60].map((mins) {
                          final isSelected = settings.defaultTimerMinutes == mins;
                          final label = mins == null ? 'Off' : '${mins}m';
                          return ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.textMuted(context),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primaryCyan,
                            backgroundColor: AppColors.card(context),
                            onSelected: (selected) {
                              if (selected) {
                                settings.setDefaultTimerMinutes(mins);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Section 3: Notifications
              _buildSectionHeader('Notifications'),
              const SizedBox(height: 12),
              _buildCardContainer(context, [
                SwitchListTile(
                  title: Text(
                    'Sleep Timer Alerts',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Notify when your sleep timer stops audio',
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 13,
                    ),
                  ),
                  activeTrackColor: AppColors.primaryCyan,
                  value: settings.notificationsEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final granted =
                          await PermissionService.requestNotificationPermission();
                      settings.setNotificationsEnabled(granted);
                    } else {
                      settings.setNotificationsEnabled(false);
                    }
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Section 4: Premium & About
              _buildSectionHeader('More'),
              const SizedBox(height: 12),
              _buildCardContainer(context, [
                ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.primaryCyan,
                  ),
                  title: Text(
                    'Premium Pass',
                    style: TextStyle(color: AppColors.text(context)),
                  ),
                  subtitle: const Text(
                    'Coming Soon • All sounds currently free',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted(context),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(context),
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textMuted(context),
                  ),
                  title: Text(
                    'App Version',
                    style: TextStyle(color: AppColors.text(context)),
                  ),
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryCyan,
      ),
    );
  }

  Widget _buildCardContainer(BuildContext context, List<Widget> children) {
    return Material(
      color: AppColors.card(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemes.borderRadiusCard),
        side: BorderSide(color: AppColors.border(context), width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRadioTile<T>({
    required BuildContext context,
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: AppColors.text(context), fontSize: 15),
      ),
      trailing: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: isSelected ? AppColors.primaryCyan : AppColors.textMuted(context),
      ),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: AppColors.border(context),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
