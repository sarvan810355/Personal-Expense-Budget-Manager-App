import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_view.dart';
import '../../application/export_providers.dart';

class ExportBackupScreen extends ConsumerWidget {
  const ExportBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime start = ref.watch(exportStartDateProvider);
    final DateTime end = ref.watch(exportEndDateProvider);
    final ExportDataType dataType = ref.watch(exportDataTypeProvider);
    final AsyncValue<List<File>> exportState = ref.watch(exportControllerProvider);
    final bool isExporting = exportState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Export & Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Date range', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(AppDateUtils.formatShort(start)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickStartDate(context, ref, start),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End date'),
                  subtitle: Text(AppDateUtils.formatShort(end)),
                  trailing: const Icon(Icons.event_outlined),
                  onTap: () => _pickEndDate(context, ref, end),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Data to export', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<ExportDataType>(
                  segments: <ButtonSegment<ExportDataType>>[
                    for (final ExportDataType type in ExportDataType.values)
                      ButtonSegment<ExportDataType>(value: type, label: Text(type.label)),
                  ],
                  selected: <ExportDataType>{dataType},
                  onSelectionChanged: isExporting
                      ? null
                      : (Set<ExportDataType> selection) {
                          ref.read(exportDataTypeProvider.notifier).state = selection.first;
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(isExporting ? 'Exporting…' : 'Export as CSV'),
            onPressed: isExporting
                ? null
                : () => ref.read(exportControllerProvider.notifier).export(
                      dataType: dataType,
                      start: start,
                      end: end,
                    ),
          ),
          const SizedBox(height: 24),
          exportState.when(
            data: (List<File> files) {
              if (files.isEmpty) {
                return const SizedBox.shrink();
              }
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Export complete', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final File file in files)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(p.basename(file.path)),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (Object e, StackTrace st) => ErrorView(message: '$e'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate(BuildContext context, WidgetRef ref, DateTime current) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(exportStartDateProvider.notifier).state = picked;
    }
  }

  Future<void> _pickEndDate(BuildContext context, WidgetRef ref, DateTime current) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(exportEndDateProvider.notifier).state = picked;
    }
  }
}
