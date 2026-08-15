import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/theme_controller.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../domain/repositories/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<String> _currencyCodes = <String>[
    'USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD', 'CAD', 'CNY', 'SGD', 'CHF',
  ];

  static const List<int> _thresholdOptions = <int>[50, 75, 90, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SectionHeader(title: 'Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
              ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(selection.first);
            },
          ),
          const SizedBox(height: 24),
          settingsAsync.when(
            data: (AppSettings settings) => _SettingsFields(settings: settings),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stackTrace) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Could not load settings: $error'),
            ),
          ),
          const SectionHeader(title: 'Demo data'),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(seedDataServiceProvider).loadDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo data loaded')),
                );
              }
            },
            child: const Text('Load demo data'),
          ),
          const SizedBox(height: 8),
          Text(
            'Adds sample accounts, expenses, income, a budget, and a trip so you can explore the app. Never runs automatically.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SettingsFields extends ConsumerWidget {
  const _SettingsFields({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsRepository repository = ref.read(settingsRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Currency'),
        DropdownButtonFormField<String>(
          initialValue: SettingsScreen._currencyCodes.contains(settings.currencyCode)
              ? settings.currencyCode
              : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          hint: Text(settings.currencyCode),
          items: SettingsScreen._currencyCodes
              .map((String code) => DropdownMenuItem<String>(value: code, child: Text(code)))
              .toList(),
          onChanged: (String? code) {
            if (code != null) {
              repository.updateCurrencyCode(code);
            }
          },
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Notifications'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable notifications'),
          subtitle: const Text('Get notified about budget alerts and reminders.'),
          value: settings.notificationsEnabled,
          onChanged: (bool enabled) => repository.updateNotificationsEnabled(enabled),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Budget alert thresholds'),
        Text(
          'Get warned when a budget reaches these percentages of its limit.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SettingsScreen._thresholdOptions.map((int threshold) {
            final bool selected = settings.budgetAlertThresholds.contains(threshold);
            return FilterChip(
              label: Text('$threshold%'),
              selected: selected,
              onSelected: (bool value) {
                final List<int> updated = <int>[...settings.budgetAlertThresholds];
                if (value) {
                  updated.add(threshold);
                } else {
                  updated.remove(threshold);
                }
                updated.sort();
                repository.updateBudgetAlertThresholds(updated);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Week starts on'),
        SegmentedButton<int>(
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: DateTime.sunday, label: Text('Sunday')),
            ButtonSegment<int>(value: DateTime.monday, label: Text('Monday')),
          ],
          selected: <int>{settings.weekStartDay},
          onSelectionChanged: (Set<int> selection) {
            repository.updateWeekStartDay(selection.first);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
