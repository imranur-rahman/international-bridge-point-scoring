import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../../../storage/storage.dart';
import '../providers.dart';
import '../widgets.dart';
import 'auction_view.dart';

/// The route for narrow screens: the score sheet and the history.
class SheetScreen extends ConsumerWidget {
  const SheetScreen({super.key, this.pastId, this.readOnly = false});

  /// The id of a past session to show read-only, or null for the active
  /// session.
  final String? pastId;

  /// True to show the active session without undo and edit.
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    if (pastId == null) {
      body = ScoreSheetPanel(readOnly: readOnly);
    } else {
      final past = ref.watch(pastSessionsProvider);
      final session = past.value
          ?.where((e) => e.id == pastId)
          .firstOrNull
          ?.session;
      body = session == null
          ? const Center(child: Text('Cannot be opened'))
          : ScoreSheetPanel(session: session, readOnly: true);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Score sheet')),
      body: body,
    );
  }
}

/// The score sheet and history tabs. It shows the active session, or
/// [session] read-only.
class ScoreSheetPanel extends ConsumerWidget {
  const ScoreSheetPanel({super.key, this.session, this.readOnly = false});

  final SessionState? session;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session ?? ref.watch(sessionProvider);
    if (s == null) return const Center(child: Text('No session'));
    final ledger = s.ledger;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(key: Key('tab-sheet'), text: 'Sheet'),
              Tab(key: Key('tab-history'), text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SheetTab(session: s, ledger: ledger),
                HistoryView(session: s, ledger: ledger, readOnly: readOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTab extends ConsumerStatefulWidget {
  const _SheetTab({required this.session, required this.ledger});

  final SessionState session;
  final LedgerSnapshot ledger;

  @override
  ConsumerState<_SheetTab> createState() => _SheetTabState();
}

class _SheetTabState extends ConsumerState<_SheetTab> {
  int? rubberNumber;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(displayProvider.select((d) => d.sheetView));
    final ledger = widget.ledger;
    final session = widget.session;
    final current = ledger.rubbers.isEmpty
        ? 1
        : ledger.rubbers.last.isComplete && !session.isEnded
        ? ledger.nextRubberNumber
        : ledger.rubbers.last.number;
    final maxRubber = current > (ledger.rubbers.lastOrNull?.number ?? 0)
        ? current
        : ledger.rubbers.last.number;
    final shown = (rubberNumber ?? current).clamp(1, maxRubber);
    final p = session.settings.players;
    final text = Theme.of(context).textTheme;
    final progress = switch (session.settings.endRule) {
      DealCountRule(:final deals) =>
        'Deal ${session.currentDealNumber} of $deals',
      TargetScoreRule(:final points) => 'Target $points points',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                progress,
                key: const Key('progress'),
                style: text.titleSmall,
              ),
            ),
            SegmentedButton<SheetView>(
              key: const Key('sheet-view'),
              showSelectedIcon: false,
              segments: [
                for (final v in SheetView.values)
                  ButtonSegment(
                    value: v,
                    label: Text(v.label, key: Key('view-${v.name}')),
                  ),
              ],
              selected: {view},
              onSelectionChanged: (v) {
                final d = ref.read(displayProvider);
                ref
                    .read(displayProvider.notifier)
                    .update(d.copyWith(sheetView: v.first));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (maxRubber > 1)
          Row(
            children: [
              const Text('Rubber'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                key: const Key('rubber-select'),
                value: shown,
                items: [
                  for (var n = 1; n <= maxRubber; n++)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) => setState(() => rubberNumber = n),
              ),
            ],
          ),
        if (view == SheetView.paper)
          PaperSheet(ledger: ledger, players: p, rubberNumber: shown)
        else
          CardSheet(ledger: ledger, players: p, rubberNumber: shown),
        const SizedBox(height: 16),
        _Totals(ledger: ledger, players: p, session: session),
      ],
    );
  }
}

/// Points of [side] in [deal] for items above or below the line.
List<int> _pointsOf(LedgerDeal deal, Side side, {required bool above}) => [
  for (final i in deal.score.items)
    if (i.side == side && i.aboveLine == above) i.points,
];

/// The traditional score pad: two columns, the line between above and
/// below, and a double line under each completed game.
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.ledger,
    required this.players,
    required this.rubberNumber,
  });

  final LedgerSnapshot ledger;
  final Players players;
  final int rubberNumber;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final deals = ledger.deals
        .where((d) => d.rubberNumber == rubberNumber)
        .toList();
    final rubber = ledger.rubbers
        .where((r) => r.number == rubberNumber)
        .firstOrNull;
    final games = rubber?.games ?? const {Side.northSouth: 0, Side.eastWest: 0};
    final gameCount = deals.isEmpty
        ? 1
        : deals.last.gameNumber + (deals.last.gameWonBy != null ? 1 : 0);

    Widget column(Side side, List<int> values, {Key? key}) => Expanded(
      child: Column(
        key: key,
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('$v', style: text.bodyLarge),
            ),
        ],
      ),
    );

    Widget split(Widget left, Widget right) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          VerticalDivider(width: 1, thickness: 1.5, color: scheme.outline),
          right,
        ],
      ),
    );

    // Above the line: newest items nearest to the line.
    final above = {
      for (final side in Side.values)
        side: [
          for (final d in deals.reversed) ..._pointsOf(d, side, above: true),
        ],
    };

    final belowRows = <Widget>[];
    for (var g = 1; g <= gameCount; g++) {
      final gameDeals = deals.where((d) => d.gameNumber == g).toList();
      final won = gameDeals.any((d) => d.gameWonBy != null);
      if (gameDeals.isEmpty && !won) continue;
      belowRows.add(
        split(
          column(Side.northSouth, [
            for (final d in gameDeals)
              ..._pointsOf(d, Side.northSouth, above: false),
          ]),
          column(Side.eastWest, [
            for (final d in gameDeals)
              ..._pointsOf(d, Side.eastWest, above: false),
          ]),
        ),
      );
      if (won) {
        belowRows.add(
          Container(
            key: Key('game-line-$g'),
            height: 5,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: scheme.outline, width: 1.5),
              ),
            ),
          ),
        );
      }
    }

    return Card(
      key: const Key('paper-sheet'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rubber $rubberNumber · Games '
              '${games[Side.northSouth]} · ${games[Side.eastWest]}',
              key: const Key('games'),
              style: text.titleSmall,
            ),
            const SizedBox(height: 8),
            split(
              Expanded(
                child: Text(
                  players.partnershipName(Side.northSouth),
                  textAlign: TextAlign.center,
                  style: text.labelLarge,
                ),
              ),
              Expanded(
                child: Text(
                  players.partnershipName(Side.eastWest),
                  textAlign: TextAlign.center,
                  style: text.labelLarge,
                ),
              ),
            ),
            const Divider(height: 8),
            split(
              column(
                Side.northSouth,
                above[Side.northSouth]!.reversed.toList(),
                key: const Key('above-ns'),
              ),
              column(
                Side.eastWest,
                above[Side.eastWest]!.reversed.toList(),
                key: const Key('above-ew'),
              ),
            ),
            Divider(
              key: const Key('the-line'),
              height: 12,
              thickness: 2.5,
              color: scheme.onSurface,
            ),
            ...belowRows,
          ],
        ),
      ),
    );
  }
}

/// A list with one card for each deal of the rubber, newest first.
class CardSheet extends StatelessWidget {
  const CardSheet({
    super.key,
    required this.ledger,
    required this.players,
    required this.rubberNumber,
  });

  final LedgerSnapshot ledger;
  final Players players;
  final int rubberNumber;

  @override
  Widget build(BuildContext context) {
    final deals = ledger.deals
        .where((d) => d.rubberNumber == rubberNumber)
        .toList()
        .reversed;
    return Column(
      key: const Key('card-sheet'),
      children: [
        for (final d in deals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SuitText(
                      'Deal ${d.index + 1} · '
                      '${describeResult(d.result, players.nameOf)}',
                    ),
                    const SizedBox(height: 4),
                    for (final side in Side.values)
                      Text(
                        '${players.partnershipName(side)}: '
                        '${d.score.totalFor(side)}',
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (deals.isEmpty) const Text('No deals in this rubber yet.'),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.ledger,
    required this.players,
    required this.session,
  });

  final LedgerSnapshot ledger;
  final Players players;
  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final bold = Theme.of(context).textTheme.titleSmall;
    final unfinished = session.isEnded
        ? ledger.unfinishedRubberBonus()
        : const <ScoreItem>[];
    int total(Side s) =>
        ledger.totalFor(s) +
        unfinished.where((i) => i.side == s).fold(0, (a, i) => a + i.points);
    TableRow row(
      String label,
      String a,
      String b, {
      TextStyle? style,
      LocalKey? key,
    }) => TableRow(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: style),
        ),
        Text(a, textAlign: TextAlign.end, style: style),
        Text(b, textAlign: TextAlign.end, style: style),
      ],
    );
    return Table(
      key: const Key('totals'),
      columnWidths: const {
        0: FlexColumnWidth(1.4),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        row(
          '',
          players.partnershipName(Side.northSouth),
          players.partnershipName(Side.eastWest),
          style: bold,
        ),
        for (final r in ledger.rubbers)
          row(
            'Rubber ${r.number}${r.isComplete ? '' : ' (current)'}',
            '${r.totals[Side.northSouth]}',
            '${r.totals[Side.eastWest]}',
          ),
        if (unfinished.isNotEmpty)
          row(
            'Unfinished rubber',
            '${unfinished.where((i) => i.side == Side.northSouth).fold(0, (a, i) => a + i.points)}',
            '${unfinished.where((i) => i.side == Side.eastWest).fold(0, (a, i) => a + i.points)}',
          ),
        row(
          'Session total',
          '${total(Side.northSouth)}',
          '${total(Side.eastWest)}',
          style: bold,
          key: const ValueKey('session-total'),
        ),
      ],
    );
  }
}

/// The list of all recorded deals, with undo, edit, and the edit marks.
class HistoryView extends ConsumerWidget {
  const HistoryView({
    super.key,
    required this.session,
    required this.ledger,
    required this.readOnly,
  });

  final SessionState session;
  final LedgerSnapshot ledger;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = session.settings.players;
    return ListView(
      key: const Key('history'),
      padding: const EdgeInsets.all(16),
      children: [
        if (!readOnly && session.records.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('undo-deal'),
              icon: const Icon(Icons.undo),
              label: const Text('Undo last deal'),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Undo the last deal?',
                  message:
                      'The app removes the last scored deal and calculates '
                      'all totals again.',
                  action: 'Undo deal',
                );
                if (ok && context.mounted) {
                  final error = await ref
                      .read(sessionProvider.notifier)
                      .send(const UndoLastDeal());
                  if (context.mounted) showError(context, error);
                }
              },
            ),
          ),
        if (session.records.isEmpty) const Text('No deals yet.'),
        for (final d in ledger.deals) _entry(context, d, p),
      ],
    );
  }

  Widget _entry(BuildContext context, LedgerDeal d, Players p) {
    final record = session.records[d.index];
    final points = [
      for (final side in Side.values)
        if (d.score.totalFor(side) != 0)
          '${p.partnershipName(side)} ${signed(d.score.totalFor(side))}',
    ].join(' · ');
    final vul = [
      for (final side in Side.values)
        if (d.vulnerability.of(side)) p.partnershipName(side),
    ];
    return Card(
      key: Key('history-${d.index + 1}'),
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        title: SuitText(
          'Deal ${d.index + 1} · ${describeResult(d.result, p.nameOf)}'
          '${points.isEmpty ? '' : ' · $points'}',
        ),
        subtitle: Text(
          'Dealer ${p.nameOf(record.dealer)} · '
          '${vul.isEmpty ? 'Nobody vulnerable' : 'Vulnerable: ${vul.join(', ')}'}'
          '${record.auctionEdited ? ' · Auction edited' : ''}',
        ),
        onTap: readOnly ? null : () => context.push('/edit/${d.index}'),
        trailing: Wrap(
          children: [
            if (record.auction != null)
              IconButton(
                key: Key('auction-${d.index + 1}'),
                tooltip: 'Auction',
                icon: const Icon(Icons.gavel_outlined),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Auction of deal ${d.index + 1}'),
                    content: AuctionHistory(
                      auction: record.auction!,
                      players: p,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            if (record.isEdited)
              IconButton(
                key: Key('edit-mark-${d.index + 1}'),
                tooltip: 'Edited',
                icon: const Icon(Icons.edit_note),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Deal ${d.index + 1} was edited'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SuitText(
                          'Original: '
                          '${describeResult(record.original!.result, p.nameOf)}',
                        ),
                        const SizedBox(height: 8),
                        for (final t in record.editTimes)
                          Text('Edited ${_formatTime(t)}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

String _formatTime(DateTime t) {
  final l = t.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)} '
      '${_two(l.hour)}:${_two(l.minute)}';
}
