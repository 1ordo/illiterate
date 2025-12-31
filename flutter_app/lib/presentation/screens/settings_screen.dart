import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../providers/settings_provider.dart';
import '../providers/language_provider.dart';

/// Settings screen for app configuration.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final health = ref.watch(backendHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Language section
          _buildSectionHeader(context, 'Language'),
          _buildLanguageTile(context, ref, settings),

          const Divider(),

          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settings.isDarkMode,
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleDarkMode();
            },
          ),

          const Divider(),

          // Features section
          _buildSectionHeader(context, 'Features'),
          SwitchListTile(
            title: const Text('Show Explanations'),
            subtitle: const Text('Display detailed correction explanations'),
            value: settings.showExplanations,
            onChanged: (_) {
              ref.read(settingsProvider.notifier).toggleExplanations();
            },
          ),
          SwitchListTile(
            title: const Text('Learning Mode'),
            subtitle: const Text('Coming soon - Track your common mistakes'),
            value: settings.learningMode,
            onChanged: null, // Disabled for now
          ),

          const Divider(),

          // Backend status
          _buildSectionHeader(context, 'Backend Status'),
          ListTile(
            leading: Icon(
              health.isHealthy ? Icons.check_circle : Icons.error,
              color: health.isHealthy ? Colors.green : Colors.red,
            ),
            title: const Text('API Server'),
            subtitle: Text(health.isHealthy ? 'Connected' : 'Disconnected'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(backendHealthProvider.notifier).checkHealth();
              },
            ),
          ),
          ListTile(
            leading: Icon(
              health.languageToolAvailable ? Icons.check_circle : Icons.warning,
              color: health.languageToolAvailable ? Colors.green : Colors.orange,
            ),
            title: const Text('LanguageTool'),
            subtitle: Text(
              health.languageToolAvailable ? 'Available' : 'Unavailable',
            ),
          ),
          ListTile(
            leading: Icon(
              health.llmAvailable ? Icons.check_circle : Icons.info,
              color: health.llmAvailable ? Colors.green : Colors.grey,
            ),
            title: const Text('LLM Service'),
            subtitle: Text(
              health.llmAvailable
                  ? 'Available'
                  : 'Unavailable (using fallback)',
            ),
          ),

          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            title: const Text('Version'),
            subtitle: Text(AppConfig.version),
          ),
          ListTile(
            title: const Text('API Endpoint'),
            subtitle: Text(AppConfig.apiBaseUrl),
          ),

          const SizedBox(height: 32),

          // Reset button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(settingsProvider.notifier).reset();
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    WidgetRef ref,
    Settings settings,
  ) {
    final languages = ref.watch(availableLanguagesProvider);

    return ListTile(
      title: const Text('Default Language'),
      subtitle: Text(settings.languageConfig.name),
      leading: Text(
        settings.languageConfig.flag,
        style: const TextStyle(fontSize: 24),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Language',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ...languages.map((lang) {
                  final isSelected = lang.code == settings.language;
                  return ListTile(
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(lang.name),
                    subtitle: Text(lang.nativeName),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).setLanguage(lang.code);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}
