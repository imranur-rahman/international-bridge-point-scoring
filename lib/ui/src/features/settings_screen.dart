import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ],
      ),
    );
  }
}
