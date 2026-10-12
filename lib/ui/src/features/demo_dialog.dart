import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../widgets.dart';
import 'demos.dart';
import 'score_sheet.dart';

/// Shows the demo game of [demo] with [values].
Future<void> showScoringDemo(
  BuildContext context,
  ScoringDemo demo,
  ScoringValues values,
) => showDialog<void>(
  context: context,
  builder: (_) => DemoDialog(demo: demo, values: values),
);

/// A step-by-step mini game that shows one scoring value.
class DemoDialog extends StatefulWidget {
  const DemoDialog({super.key, required this.demo, required this.values});

  final ScoringDemo demo;
  final ScoringValues values;

  @override
  State<DemoDialog> createState() => _DemoDialogState();
}

class _DemoDialogState extends State<DemoDialog> {
  int step = 1;

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final values = widget.values;
    final count = demo.steps.length;
    final ledger = demo.replay(step, values);
    final current = ledger.deals.last;
    final p = demoPlayers;
    final text = Theme.of(context).textTheme;
    final endItems = demo.sessionEndItems(step, values);
    final valueIsZero = values[demo.field] == 0;

    return Dialog(
      key: const Key('demo'),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SuitText('Demo: ${demo.field.label}', style: text.titleMedium),
              Text(
                'Step $step of $count',
                key: const Key('demo-step'),
                style: text.labelLarge,
              ),
              const SizedBox(height: 12),
              for (final d in ledger.deals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SuitText(
                    'Deal ${d.index + 1} · '
                    '${describeResult(d.result, p.nameOf)}',
                    style: d == current
                        ? const TextStyle(fontWeight: FontWeight.w600)
                        : TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _vulnerabilityText(current.vulnerability),
                key: const Key('demo-vulnerability'),
                style: text.bodySmall,
              ),
              const SizedBox(height: 4),
              SuitText(demo.steps[step - 1].text, key: const Key('demo-text')),
              if (current.gameWonBy case final side?)
                Text('${p.partnershipName(side)} win a game.'),
              if (current.rubberWonBy case final side?)
                Text('${p.partnershipName(side)} win the rubber.'),
              const SizedBox(height: 12),
              _HighlightedBreakdown(
                items: current.score.items,
                highlight: demo.highlight,
              ),
              if (endItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'The session ends during the rubber.',
                  key: Key('demo-session-end'),
                ),
                const SizedBox(height: 4),
                _HighlightedBreakdown(
                  items: endItems,
                  highlight: demo.highlight,
                ),
              ],
              if (valueIsZero)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'This value is 0 in these values, so it adds no points.',
                    key: const Key('demo-zero'),
                    style: text.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              PaperSheet(
                ledger: ledger,
                players: p,
                rubberNumber: current.rubberNumber,
              ),
              const SizedBox(height: 16),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const Key('demo-back'),
                    onPressed: step > 1 ? () => setState(() => step--) : null,
                    child: const Text('Back'),
                  ),
                  if (step < count)
                    FilledButton(
                      key: const Key('demo-next'),
                      onPressed: () => setState(() => step++),
                      child: const Text('Next'),
                    )
                  else
                    FilledButton(
                      key: const Key('demo-done'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The score items of a deal. The items of [highlight] are marked.
class _HighlightedBreakdown extends StatelessWidget {
  const _HighlightedBreakdown({required this.items, required this.highlight});

  final List<ScoreItem> items;
  final ScoreComponent highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) return const Text('No points in this deal.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Container(
            key: item.component == highlight
                ? Key('demo-highlight-${item.component.name}')
                : null,
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: item.component == highlight
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.component.label}: ${item.points}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.component == highlight
                          ? scheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    item.component == highlight
                        ? 'This value · ${demoPlayers.partnershipName(item.side)}'
                        : demoPlayers.partnershipName(item.side),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: item.component == highlight
                          ? scheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Vulnerable: Alice & Carol" or "Nobody vulnerable" for a demo deal.
String _vulnerabilityText(Vulnerability v) {
  final sides = [
    for (final side in Side.values)
      if (v.of(side)) demoPlayers.partnershipName(side),
  ];
  return sides.isEmpty
      ? 'Nobody vulnerable'
      : 'Vulnerable: ${sides.join(', ')}';
}
