import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../session/session.dart';
import '../providers.dart';
import '../widgets.dart';
import 'setup_wizard.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, this.pastId});

  /// The id of a past session, or null for the active session.
  final String? pastId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(sessionProvider);
    final SessionState? session;
    if (pastId == null) {
      session = active;
    } else {
      final past = ref.watch(pastSessionsProvider);
      if (past.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      session = past.value?.where((e) => e.id == pastId).firstOrNull?.session;
    }
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Cannot be opened')),
      );
    }
    final s = session;
    final summary = SessionSummary.of(s);
    final p = s.settings.players;
    final text = Theme.of(context).textTheme;
    final otherActive = pastId != null && active != null && !active.isEnded;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final summary'),
        automaticallyImplyLeading: pastId != null,
      ),
      body: ScrollPage(
        children: [
          Text(
            'Session ended · ${summary.dealCount} deals',
            style: text.titleSmall,
          ),
          const SizedBox(height: 12),
          Text(
            summary.winner == null
                ? 'Tie'
                : '${p.partnershipName(summary.winner!)} win '
                      'by ${summary.margin} points',
            key: const Key('winner'),
            style: text.headlineSmall,
          ),
          const SectionTitle('Rubbers'),
          _RubberTable(summary: summary, players: p),
          if (summary.unfinishedBonus.isNotEmpty) ...[
            const SectionTitle('Unfinished rubber bonus'),
            for (final i in summary.unfinishedBonus)
              Text(
                '${p.partnershipName(i.side)} +${i.points}',
                key: Key('unfinished-${i.side.name}'),
              ),
          ],
          const SectionTitle('Score by deal'),
          SizedBox(
            height: 220,
            child: _Chart(summary: summary, players: p),
          ),
          const SectionTitle('Biggest deals'),
          if (summary.biggestDeals.isEmpty) const Text('No points scored.'),
          for (final b in summary.biggestDeals)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SuitText(
                'Deal ${b.dealNumber} · '
                '${describeResult(b.result, p.nameOf)} · '
                '${p.partnershipName(b.side)} +${b.points}',
                key: Key('big-${b.dealNumber}-${b.side.name}'),
              ),
            ),
          const SectionTitle('Player statistics'),
          _StatsTable(summary: summary, players: p),
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('view-sheet'),
            onPressed: () => context.push(
              pastId == null ? '/sheet?readOnly=true' : '/past/$pastId/sheet',
            ),
            child: const Text('View score sheet'),
          ),
          if (!otherActive) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('rematch'),
              onPressed: () {
                ref.read(setupPrefillProvider.notifier).set(rematchSettings(s));
                context.go('/setup');
              },
              child: const Text('New session, same players'),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('home'),
            onPressed: () => context.go('/'),
            child: const Text('Home'),
          ),
        ],
      ),
    );
  }
}

class _RubberTable extends StatelessWidget {
  const _RubberTable({required this.summary, required this.players});

  final SessionSummary summary;
  final Players players;

  @override
  Widget build(BuildContext context) {
    final bold = Theme.of(context).textTheme.titleSmall;
    TableRow row(String a, String b, String c, {TextStyle? style}) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(a, style: style),
        ),
        Text(b, textAlign: TextAlign.end, style: style),
        Text(c, textAlign: TextAlign.end, style: style),
      ],
    );
    return Table(
      key: const Key('rubber-table'),
      children: [
        row(
          '',
          players.partnershipName(Side.northSouth),
          players.partnershipName(Side.eastWest),
          style: bold,
        ),
        for (final r in summary.rubbers)
          row(
            'Rubber ${r.number}${r.isComplete ? '' : ' *'}',
            '${r.totals[Side.northSouth]}',
            '${r.totals[Side.eastWest]}',
          ),
        row(
          'Session',
          '${summary.finalTotals[Side.northSouth]}',
          '${summary.finalTotals[Side.eastWest]}',
          style: bold,
        ),
      ],
    );
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.summary, required this.players});

  final SessionSummary summary;
  final Players players;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    Widget cell(String t, {TextStyle? s, TextAlign? align}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(t, style: s, textAlign: align ?? TextAlign.center),
    );
    return Table(
      key: const Key('stats'),
      columnWidths: const {0: FlexColumnWidth(2)},
      children: [
        TableRow(
          children: [
            cell('Player', s: style, align: TextAlign.start),
            cell('Decl.', s: style),
            cell('Made', s: style),
            cell('Down', s: style),
            cell('Slams', s: style),
          ],
        ),
        for (final st in summary.playerStats)
          TableRow(
            key: ValueKey('stats-${st.seat.name}'),
            children: [
              cell(players.nameOf(st.seat), align: TextAlign.start),
              cell('${st.declared}'),
              cell('${st.fulfilled}'),
              cell('${st.down}'),
              cell('${st.slamsMade}/${st.slamsBid}'),
            ],
          ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.summary, required this.players});

  final SessionSummary summary;
  final Players players;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = {
      Side.northSouth: scheme.primary,
      Side.eastWest: scheme.tertiary,
    };
    final target = summary.target;
    return Column(
      children: [
        Wrap(
          spacing: 16,
          children: [
            for (final side in Side.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 3, color: colors[side]),
                  const SizedBox(width: 6),
                  Text(players.partnershipName(side)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            key: const Key('chart'),
            LineChartData(
              minY: 0,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(),
                rightTitles: AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 24),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (target != null)
                    HorizontalLine(
                      y: target.toDouble(),
                      color: scheme.error,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Target $target',
                      ),
                    ),
                ],
              ),
              lineBarsData: [
                for (final side in Side.values)
                  LineChartBarData(
                    spots: [
                      for (final pt in summary.chart)
                        FlSpot(
                          pt.dealNumber.toDouble(),
                          pt.totals[side]!.toDouble(),
                        ),
                    ],
                    color: colors[side],
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
