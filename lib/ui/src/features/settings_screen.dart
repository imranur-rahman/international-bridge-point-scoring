import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../storage/storage.dart';
import '../providers.dart';
import '../widgets.dart';

/// The display settings of this device. A change applies at once.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(displayProvider);
    void update(DisplayPreferences p) =>
        ref.read(displayProvider.notifier).update(p);
    Widget choice<T extends Enum>({
      required String title,
      required List<T> values,
      required T selected,
      required String Function(T) label,
      required void Function(T) onSelected,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoiceChip(
                key: Key('setting-${v.name}'),
                label: Text(label(v)),
                selected: v == selected,
                onSelected: (_) => onSelected(v),
              ),
          ],
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ScrollPage(
        children: [
          choice<ThemeModeSetting>(
            title: 'Theme',
            values: ThemeModeSetting.values,
            selected: d.themeMode,
            label: (v) => v.label,
            onSelected: (v) => update(d.copyWith(themeMode: v)),
          ),
          choice<TextSizeSetting>(
            title: 'Text size',
            values: TextSizeSetting.values,
            selected: d.textSize,
            label: (v) => v.label,
            onSelected: (v) => update(d.copyWith(textSize: v)),
          ),
          choice<SuitColorsSetting>(
            title: 'Suit colors',
            values: SuitColorsSetting.values,
            selected: d.suitColors,
            label: (v) => v.label,
            onSelected: (v) => update(d.copyWith(suitColors: v)),
          ),
          const SizedBox(height: 12),
          SuitText(
            '♣  ♦  ♥  ♠',
            key: const Key('suit-preview'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'These settings change only the display on this device. They '
            'never change a score.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SectionTitle('Storage'),
          const _StorageSection(),
        ],
      ),
    );
  }
}

/// "Refresh app files" and "Delete all data" (design decision D5).
class _StorageSection extends ConsumerStatefulWidget {
  const _StorageSection();

  @override
  ConsumerState<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends ConsumerState<_StorageSection> {
  late final Future<int> _size;

  @override
  void initState() {
    super.initState();
    final files = ref.read(appFilesProvider);
    _size = files.hasOfflineCopy ? files.offlineSize() : Future.value(0);
  }

  Future<void> _refresh() async {
    final ok = await confirm(
      context,
      title: 'Refresh app files?',
      message:
          'The app deletes its offline copy and loads its files again from '
          'the network. Your sessions and settings stay.',
      action: 'Refresh',
    );
    if (ok) await ref.read(appFilesProvider).refresh();
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAllDialog(),
    );
    if (ok != true || !mounted) return;
    await resetAllData(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data on this device was deleted')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(appFilesProvider);
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (files.hasOfflineCopy) ...[
          FutureBuilder<int>(
            future: _size,
            builder: (context, snapshot) => Text(
              snapshot.hasData
                  ? 'Offline copy of the app: ${formatBytes(snapshot.data!)}'
                  : 'Offline copy of the app: …',
              key: const Key('offline-size'),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('refresh-app-files'),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh app files'),
              onPressed: _refresh,
            ),
          ),
          Text('Downloads the newest version. Your scores stay.', style: small),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('delete-all-data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete all data'),
            onPressed: _deleteAll,
          ),
        ),
        Text(
          'Sessions, past sessions, House rules, and settings on this '
          'device. This cannot be undone.',
          style: small,
        ),
      ],
    );
  }
}

/// Asks the user to type "delete" before all data is deleted.
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final TextEditingController _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  bool get _confirmed => _word.text.trim().toLowerCase() == 'delete';

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('delete-all-dialog'),
    title: const Text('Delete all data?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This deletes all sessions, past sessions, House rules, and '
          'settings on this device. This cannot be undone.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('delete-word'),
          controller: _word,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Type "delete" to confirm',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('confirm-delete-all'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: _confirmed ? () => Navigator.pop(context, true) : null,
        child: const Text('Delete'),
      ),
    ],
  );
}

/// "3.1 MB", "640 KB", or "512 B".
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
