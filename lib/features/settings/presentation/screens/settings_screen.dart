import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/theme_controller.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

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
