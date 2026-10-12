import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scoring/scoring.dart';
import '../providers.dart';
import '../widgets.dart';
import 'help_button.dart';
import 'help_texts.dart';
import 'demo_dialog.dart';
import 'demos.dart';
import 'sample_calculator.dart';

/// The "House rules" screen, or the read-only "Standard" screen.
class HouseRulesScreen extends ConsumerStatefulWidget {
  const HouseRulesScreen({super.key, required this.preset});

  final ScoringPreset preset;

  @override
  ConsumerState<HouseRulesScreen> createState() => _HouseRulesScreenState();
}

class _HouseRulesScreenState extends ConsumerState<HouseRulesScreen> {
  final ScoringValues standard = ScoringValues.standard();
  late ScoringValues saved;
  late final Map<ScoringField, TextEditingController> controllers;
  late final Set<ScoringGroup> initiallyExpanded;
  final ValueNotifier<Object?> openHelp = ValueNotifier(null);

  bool get readOnly => widget.preset == ScoringPreset.standard;

  @override
  void initState() {
    super.initState();
    saved = readOnly ? standard : ref.read(houseRulesProvider);
    controllers = {
      for (final f in ScoringField.values)
        f: TextEditingController(text: '${saved[f]}'),
    };
    final changed = saved.differsFrom(standard);
    initiallyExpanded = {for (final f in changed) f.group};
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    openHelp.dispose();
    super.dispose();
  }

  /// The error of one field, or null.
  String? errorOf(ScoringField f) {
    final v = int.tryParse(controllers[f]!.text.trim());
    if (v == null) return 'Whole number';
    if (v < f.minimum || v > ScoringField.maximum) {
      return '${f.minimum} to ${ScoringField.maximum}';
    }
    return null;
  }

  bool get hasErrors => ScoringField.values.any((f) => errorOf(f) != null);

  /// The values on the screen, or null when one is not valid.
  ScoringValues? get current {
    if (hasErrors) return null;
    var v = saved;
    for (final f in ScoringField.values) {
      v = v.withValue(f, int.parse(controllers[f]!.text.trim()));
    }
    return v;
  }

  bool get dirty => ScoringField.values.any(
    (f) => controllers[f]!.text.trim() != '${saved[f]}',
  );

  bool differsFromStandard(ScoringField f) =>
      controllers[f]!.text.trim() != '${standard[f]}';

  Future<void> save() async {
    final values = current;
    if (values == null) return;
    await ref.read(houseRulesProvider.notifier).save(values);
    setState(() => saved = values);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('House rules saved')));
    }
  }

  Future<void> restore() async {
    final ok = await confirm(
      context,
      title: 'Restore House rules defaults?',
      message: 'All House rules values go back to their defaults.',
      action: 'Restore',
    );
    if (!ok) return;
    final defaults = ScoringValues.houseDefaults();
    setState(() {
      for (final f in ScoringField.values) {
        controllers[f]!.text = '${defaults[f]}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: readOnly || !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirm(
          context,
          title: 'Discard changes?',
          message: 'The changes on this screen are not saved.',
          action: 'Discard',
        );
        if (discard && context.mounted) {
          setState(() {
            for (final f in ScoringField.values) {
              controllers[f]!.text = '${saved[f]}';
            }
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.preset.label),
          actions: [
            if (!readOnly)
              TextButton(
                key: const Key('save'),
                onPressed: hasErrors || !dirty ? null : save,
                child: const Text('Save'),
              ),
          ],
        ),
        body: HelpScope(
          open: openHelp,
          child: ScrollPage(
            children: [
              Text(
                readOnly
                    ? 'The values of the Laws of Contract Bridge. You cannot '
                          'change them.'
                    : '● = different from Standard',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final group in ScoringGroup.values) groupTile(group),
              if (!readOnly) ...[
                const SizedBox(height: 8),
                Card(
                  child: ExpansionTile(
                    key: const Key('calculator'),
                    title: const Text('Try a sample deal'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [SampleCalculator(houseValues: current)],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const Key('restore'),
                  onPressed: restore,
                  child: const Text('Restore House rules defaults'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget groupTile(ScoringGroup group) {
    final fields = ScoringField.inGroup(group);
    final changed = fields.any(differsFromStandard);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ExpansionTile(
          key: Key('group-${group.name}'),
          initiallyExpanded: initiallyExpanded.contains(group),
          title: Text(group.label),
          subtitle: Text(
            '${fields.length} values${changed ? ' · ●' : ''}',
            key: Key('group-sub-${group.name}'),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
          children: [
            for (final f in fields) fieldRow(f),
            if (group == ScoringGroup.undertricks ||
                group == ScoringGroup.doubleRedouble)
              Row(
                children: [
                  const Expanded(child: Text('Redoubled = 2 × doubled')),
                  HelpButton(
                    help: redoubledHelp,
                    id: 'redoubled-${group.name}',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget fieldRow(ScoringField f) {
    final mark = differsFromStandard(f);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            child: mark
                ? Text('●', key: Key('mark-${f.name}'))
                : const SizedBox.shrink(),
          ),
          Expanded(child: SuitText(f.label)),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: TextField(
              key: Key('field-${f.name}'),
              controller: controllers[f],
              readOnly: readOnly,
              enabled: !readOnly,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                errorText: readOnly ? null : errorOf(f),
                errorMaxLines: 2,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          HelpButton(
            key: Key('help-${f.name}'),
            help: helpTexts[f]!,
            id: f,
            standardDefault: f.standardDefault,
            hasDemo: true,
            onDemo: current == null
                ? null
                : () => showScoringDemo(context, scoringDemos[f]!, current!),
          ),
        ],
      ),
    );
  }
}
