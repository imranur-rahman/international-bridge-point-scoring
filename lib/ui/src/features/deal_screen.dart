import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auction/auction.dart';
import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../providers.dart';
import '../widgets.dart';
import 'auction_view.dart';
import 'score_sheet.dart';

/// The width from which the deal and the score sheet show side by side.
const double twoPaneWidth = 900;

Future<void> sendCommand(
  BuildContext context,
  WidgetRef ref,
  SessionCommand command,
) async {
  final error = await ref.read(sessionProvider.notifier).send(command);
  if (context.mounted) showError(context, error);
}

class DealScreen extends ConsumerWidget {
  const DealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= twoPaneWidth;
        return Scaffold(
          appBar: AppBar(
            title: Text(_title(session), key: const Key('deal-title')),
            actions: [
              if (!wide)
                TextButton.icon(
                  key: const Key('open-sheet'),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Sheet'),
                  onPressed: () => context.push('/sheet'),
                ),
              _DealMenu(session: session),
            ],
          ),
          body: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _DealPane()),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: (constraints.maxWidth * 0.42).clamp(360, 520),
                      child: const ScoreSheetPanel(key: Key('side-sheet')),
                    ),
                  ],
                )
              : const _DealPane(),
        );
      },
    );
  }

  static String _title(SessionState s) {
    final n = s.currentDealNumber;
    return switch (s.settings.endRule) {
      DealCountRule(:final deals) => 'Deal $n of $deals',
      TargetScoreRule(:final points) => 'Deal $n · Target $points',
    };
  }
}

enum _MenuAction { undo, end, sessionSettings, settings, home }

class _DealMenu extends ConsumerWidget {
  const _DealMenu({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = session.draft?.stage;
    final betweenDeals =
        !session.isEnded &&
        (stage == null ||
            stage == DealStage.start ||
            stage == DealStage.scored);
    return PopupMenuButton<_MenuAction>(
      key: const Key('deal-menu'),
      tooltip: 'Menu',
      onSelected: (action) async {
        switch (action) {
          case _MenuAction.undo:
            final ok = await confirm(
              context,
              title: 'Undo the last deal?',
              message:
                  'The app removes the last scored deal and calculates all '
                  'totals again. The entries of the current deal are lost.',
              action: 'Undo deal',
            );
            if (ok && context.mounted) {
              await sendCommand(context, ref, const UndoLastDeal());
            }
          case _MenuAction.end:
            final ok = await confirm(
              context,
              title: 'End the session?',
              message: 'The app adds the unfinished rubber bonus, if it is on.',
              action: 'End session',
            );
            if (ok && context.mounted) {
              await sendCommand(context, ref, const EndSession());
              if (context.mounted) context.go('/summary');
            }
          case _MenuAction.sessionSettings:
            await showDialog<void>(
              context: context,
              builder: (_) => SessionSettingsDialog(settings: session.settings),
            );
          case _MenuAction.settings:
            await context.push('/settings');
          case _MenuAction.home:
            context.go('/');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.undo,
          enabled: session.records.isNotEmpty,
          child: const Text('Undo last deal'),
        ),
        PopupMenuItem(
          value: _MenuAction.end,
          enabled: betweenDeals,
          child: const Text('End session'),
        ),
        const PopupMenuItem(
          value: _MenuAction.sessionSettings,
          child: Text('Session settings'),
        ),
        const PopupMenuItem(
          value: _MenuAction.settings,
          child: Text('Settings'),
        ),
        const PopupMenuItem(value: _MenuAction.home, child: Text('Home')),
      ],
    );
  }
}

/// The read-only settings of a started session.
class SessionSettingsDialog extends StatelessWidget {
  const SessionSettingsDialog({super.key, required this.settings});

  final SessionSettings settings;

  @override
  Widget build(BuildContext context) {
    final p = settings.players;
    final rule = switch (settings.endRule) {
      DealCountRule(:final deals) => '$deals deals',
      TargetScoreRule(:final points) => 'Target $points points',
    };
    String onOff(bool v) => v ? 'On' : 'Off';
    return AlertDialog(
      key: const Key('session-settings'),
      title: const Text('Session settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('These settings cannot change during a session.'),
            const SizedBox(height: 12),
            for (final seat in Seat.values)
              Text('${seat.label}: ${p.nameOf(seat)}'),
            const SizedBox(height: 8),
            Text('First dealer: ${p.nameOf(settings.firstDealer)}'),
            Text('End rule: $rule'),
            Text('Bidding step: ${onOff(settings.biddingStep)}'),
            Text('Honors: ${onOff(settings.components.honors)}'),
            Text(
              'Unfinished rubber bonus: '
              '${onOff(settings.components.unfinishedRubberBonus)}',
            ),
            Text('Scoring: ${settings.preset.label}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DealPane extends ConsumerWidget {
  const _DealPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider)!;
    final draft = session.draft;
    if (draft == null) {
      return ScrollPage(
        children: [
          const Text('The session has ended.'),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('final-summary'),
            onPressed: () => context.go('/summary'),
            child: const Text('Final summary'),
          ),
        ],
      );
    }
    return ScrollPage(
      children: [
        StageBar(stage: draft.stage, biddingStep: session.settings.biddingStep),
        const SizedBox(height: 16),
        switch (draft.stage) {
          DealStage.start => _StartView(session: session, draft: draft),
          DealStage.auction => AuctionView(session: session, draft: draft),
          DealStage.contract => _ContractView(session: session, draft: draft),
          DealStage.play => _PlayView(session: session, draft: draft),
          DealStage.result => _ResultView(session: session, draft: draft),
          DealStage.scored => _ScoredView(session: session),
        },
      ],
    );
  }
}

/// Shows all stages of a deal and marks the current stage.
class StageBar extends StatelessWidget {
  const StageBar({super.key, required this.stage, required this.biddingStep});

  final DealStage stage;
  final bool biddingStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stages = [
      for (final s in DealStage.values)
        if (s != DealStage.auction || biddingStep) s,
    ];
    return Wrap(
      key: const Key('stage-bar'),
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in stages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: s == stage
                  ? scheme.primary
                  : s.index < stage.index
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              s.label,
              key: s == stage ? const Key('current-stage') : null,
              style: TextStyle(
                color: s == stage ? scheme.onPrimary : scheme.onSurface,
                fontWeight: s == stage ? FontWeight.w600 : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _StartView extends ConsumerWidget {
  const _StartView({required this.session, required this.draft});

  final SessionState session;
  final DealDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = session.settings.players;
    final vul = ref.watch(ledgerProvider)!.nextVulnerability;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Deal ${session.currentDealNumber}', style: text.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Dealer: ${p.nameOf(draft.dealer)} (${draft.dealer.label})',
          key: const Key('dealer'),
        ),
        const SizedBox(height: 12),
        for (final side in Side.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: VulnerabilityLabel(
              key: Key('vul-${side.name}'),
              name: p.partnershipName(side),
              vulnerable: vul.of(side),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('advance'),
          onPressed: () => sendCommand(context, ref, const AdvanceFromStart()),
          child: Text(
            session.settings.biddingStep ? 'Start auction' : 'Enter contract',
          ),
        ),
      ],
    );
  }
}

class _ContractView extends ConsumerWidget {
  const _ContractView({required this.session, required this.draft});

  final SessionState session;
  final DealDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = session.settings.players;
    final input = draft.contract;
    void set(ContractInput i) => sendCommand(context, ref, SetContract(i));

    if (session.settings.biddingStep) {
      final c = input.toContract()!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Final contract from the auction'),
          const SizedBox(height: 8),
          ContractHeadline(contract: c, players: p),
          const SizedBox(height: 16),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('back'),
                onPressed: () => sendCommand(context, ref, const Back()),
                child: const Text('Back to auction'),
              ),
              FilledButton(
                key: const Key('confirm-contract'),
                onPressed: () =>
                    sendCommand(context, ref, const ConfirmContract()),
                child: const Text('Continue'),
              ),
            ],
          ),
        ],
      );
    }

    ContractInput copy({
      int? level,
      Strain? strain,
      Doubling? doubling,
      Seat? declarer,
    }) => ContractInput(
      level: level ?? input.level,
      strain: strain ?? input.strain,
      doubling: doubling ?? input.doubling,
      declarer: declarer ?? input.declarer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Level'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var l = 1; l <= 7; l++)
              ChoiceChip(
                key: Key('level-$l'),
                label: Text('$l'),
                selected: input.level == l,
                onSelected: (_) => set(copy(level: l)),
              ),
          ],
        ),
        const SectionTitle('Denomination'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in Strain.values)
              ChoiceChip(
                key: Key('strain-${s.name}'),
                label: SuitText(s.symbol),
                selected: input.strain == s,
                onSelected: (_) => set(copy(strain: s)),
              ),
          ],
        ),
        const SectionTitle('Double'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in Doubling.values)
              ChoiceChip(
                key: Key('doubling-${d.name}'),
                label: Text(switch (d) {
                  Doubling.none => 'Undoubled',
                  Doubling.doubled => 'Doubled',
                  Doubling.redoubled => 'Redoubled',
                }),
                selected: input.doubling == d,
                onSelected: (_) => set(copy(doubling: d)),
              ),
          ],
        ),
        const SectionTitle('Declarer'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final seat in Seat.values)
              ChoiceChip(
                key: Key('declarer-${seat.name}'),
                label: Text('${p.nameOf(seat)} (${seat.letter})'),
                selected: input.declarer == seat,
                onSelected: (_) => set(copy(declarer: seat)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (input.toContract() case final c?)
          ContractHeadline(contract: c, players: p),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            OutlinedButton(
              key: const Key('back'),
              onPressed: () => sendCommand(context, ref, const Back()),
              child: const Text('Back'),
            ),
            OutlinedButton(
              key: const Key('pass-out'),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Passed out?',
                  message: 'All four players passed. The deal scores 0.',
                  action: 'Passed out',
                );
                if (ok && context.mounted) {
                  await sendCommand(context, ref, const PassOut());
                }
              },
              child: const Text('Passed out'),
            ),
            FilledButton(
              key: const Key('confirm-contract'),
              onPressed: input.isComplete
                  ? () => sendCommand(context, ref, const ConfirmContract())
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }
}

/// "4♠ doubled by Carol" in large text.
class ContractHeadline extends StatelessWidget {
  const ContractHeadline({
    super.key,
    required this.contract,
    required this.players,
  });

  final Contract contract;
  final Players players;

  @override
  Widget build(BuildContext context) {
    final d = switch (contract.doubling) {
      Doubling.none => '',
      Doubling.doubled => ' doubled',
      Doubling.redoubled => ' redoubled',
    };
    return SuitText(
      '${contract.bid}$d by ${players.nameOf(contract.declarer)}',
      key: const Key('contract-headline'),
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _PlayView extends ConsumerWidget {
  const _PlayView({required this.session, required this.draft});

  final SessionState session;
  final DealDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = session.settings.players;
    final contract = draft.contract.toContract()!;
    final roles = PlayRoles.of(contract.declarer);
    final vul = ref.watch(ledgerProvider)!.nextVulnerability;
    Widget role(String label, Seat seat, Key key) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Text(
              '${p.nameOf(seat)} (${seat.label})',
              key: key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContractHeadline(contract: contract, players: p),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                role('Declarer', roles.declarer, const Key('role-declarer')),
                role('Dummy', roles.dummy, const Key('role-dummy')),
                role(
                  'Opening lead',
                  roles.openingLeader,
                  const Key('role-lead'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final side in Side.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: VulnerabilityLabel(
              name: p.partnershipName(side),
              vulnerable: vul.of(side),
            ),
          ),
        const SizedBox(height: 16),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          overflowSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('back'),
              onPressed: () => sendCommand(context, ref, const Back()),
              child: const Text('Back'),
            ),
            FilledButton(
              key: const Key('finish-play'),
              onPressed: () => sendCommand(context, ref, const FinishPlay()),
              child: const Text('Enter result'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultView extends ConsumerStatefulWidget {
  const _ResultView({required this.session, required this.draft});

  final SessionState session;
  final DealDraft draft;

  @override
  ConsumerState<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<_ResultView> {
  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final draft = widget.draft;
    final p = session.settings.players;
    final contract = draft.contract.toContract()!;
    final tricks = draft.tricksTaken;
    final result = tricks == null
        ? null
        : DealResult(contract: contract, tricksTaken: tricks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContractHeadline(contract: contract, players: p),
        Text('Needs ${contract.tricksNeeded} tricks', key: const Key('needs')),
        const SectionTitle('Result'),
        ResultPicker(
          level: contract.level,
          selected: tricks,
          onSelected: (t) => sendCommand(context, ref, SetTricks(t)),
        ),
        const SizedBox(height: 8),
        Text(
          result?.fullResult ?? 'Select the result',
          key: const Key('full-result'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (session.settings.components.honors) ...[
          const SectionTitle('Honors'),
          HonorsPicker(
            strain: contract.strain,
            players: p,
            values: session.settings.values,
            honors: draft.honors,
            onChanged: (h) => sendCommand(context, ref, SetHonors(h)),
          ),
        ],
        const SizedBox(height: 16),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          overflowSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('back'),
              onPressed: () => sendCommand(context, ref, const Back()),
              child: const Text('Back'),
            ),
            FilledButton(
              key: const Key('score-deal'),
              onPressed: SessionController.draftResult(session) == null
                  ? null
                  : () => sendCommand(context, ref, const ScoreDeal()),
              child: const Text('Score deal'),
            ),
          ],
        ),
      ],
    );
  }
}

/// One button for each possible result. On a narrow screen, "Down 3" to
/// "+3" show first, and the other results are in a row that scrolls
/// sideways.
class ResultPicker extends StatelessWidget {
  const ResultPicker({
    super.key,
    required this.level,
    required this.selected,
    required this.onSelected,
  });

  final int level;
  final int? selected;
  final ValueChanged<int> onSelected;

  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final options = ResultOption.forLevel(level);
    Widget button(ResultOption o) => ChoiceChip(
      key: Key('result-${o.label}'),
      label: Text(o.label, maxLines: 1),
      selected: o.tricksTaken == selected,
      onSelected: (_) => onSelected(o.tricksTaken),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final o in options) button(o)],
          );
        }
        final main = options.where((o) => o.difference >= -3).toList();
        // The other results, nearest first: Down 4, Down 5, ...
        final more = options
            .where((o) => o.difference < -3)
            .toList()
            .reversed
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              key: const Key('result-main'),
              spacing: gap,
              runSpacing: gap,
              children: [for (final o in main) button(o)],
            ),
            if (more.isNotEmpty) ...[
              const SizedBox(height: gap),
              SizedBox(
                height: 52 * MediaQuery.textScalerOf(context).scale(1),
                child: ListView.separated(
                  key: const Key('result-scroll'),
                  scrollDirection: Axis.horizontal,
                  itemCount: more.length,
                  separatorBuilder: (_, _) => const SizedBox(width: gap),
                  itemBuilder: (_, i) => Center(child: button(more[i])),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The selection of the majority side and its honors holding. It sends
/// only complete entries: a holding with its side, or "None (2 + 2)".
class HonorsPicker extends StatefulWidget {
  const HonorsPicker({
    super.key,
    required this.strain,
    required this.players,
    required this.values,
    required this.honors,
    required this.onChanged,
  });

  final Strain strain;
  final Players players;
  final ScoringValues values;
  final Honors? honors;
  final ValueChanged<Honors?> onChanged;

  @override
  State<HonorsPicker> createState() => _HonorsPickerState();
}

class _HonorsPickerState extends State<HonorsPicker> {
  late Side? side = widget.honors?.side;

  @override
  Widget build(BuildContext context) {
    final holdings = HonorsHolding.forStrain(widget.strain);
    final current = widget.honors;
    final isNone = current?.holding.isNone ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.strain.isSuit
              ? 'Which side held 3 or more trump honors?'
              : 'Which side held 3 or more aces?',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in Side.values)
              ChoiceChip(
                key: Key('honors-side-${s.name}'),
                label: Text(widget.players.partnershipName(s)),
                selected: side == s && !isNone,
                onSelected: (_) {
                  setState(() => side = s);
                  final h = current?.holding;
                  if (h != null && !h.isNone) widget.onChanged(Honors(h, s));
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in holdings)
              ChoiceChip(
                key: Key('holding-${h.name}'),
                label: Text('${h.label} · ${h.points(widget.values)}'),
                selected: current?.holding == h,
                onSelected: (h.isNone || side != null)
                    ? (_) => widget.onChanged(
                        h.isNone ? Honors.none : Honors(h, side),
                      )
                    : null,
              ),
          ],
        ),
        if (side == null && !isNone)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Select the side first.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _ScoredView extends ConsumerWidget {
  const _ScoredView({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider)!;
    final deal = ledger.deals.last;
    final p = session.settings.players;
    final result = deal.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Deal ${deal.index + 1} scored',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ContractHeadline(contract: result.contract, players: p),
        Text(result.fullResult, key: const Key('scored-result')),
        const SizedBox(height: 12),
        ScoreBreakdown(score: deal.score, players: p),
        if (deal.gameWonBy case final side?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${p.partnershipName(side)} win a game.'),
          ),
        if (deal.rubberWonBy case final side?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${p.partnershipName(side)} win the rubber.'),
          ),
        const SizedBox(height: 16),
        if (session.isEnded)
          FilledButton(
            key: const Key('final-summary'),
            onPressed: () => context.go('/summary'),
            child: const Text('Final summary'),
          )
        else
          FilledButton(
            key: const Key('next-deal'),
            onPressed: () => sendCommand(context, ref, const NextDeal()),
            child: const Text('Next deal'),
          ),
      ],
    );
  }
}

/// The score components of one deal, with the side of each.
class ScoreBreakdown extends StatelessWidget {
  const ScoreBreakdown({super.key, required this.score, required this.players});

  final DealScore score;
  final Players players;

  @override
  Widget build(BuildContext context) {
    if (score.items.isEmpty) return const Text('No points.');
    return Card(
      key: const Key('breakdown'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final item in score.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.component.label}: ${item.points}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${players.partnershipName(item.side)} · '
                        '${item.aboveLine ? 'above' : 'below'}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Exposed for tests of the auction outcome text.
String auctionStatus(Auction auction, Players players) {
  final seat = auction.toCall;
  return seat == null
      ? 'The auction has ended'
      : '${players.nameOf(seat)} to call';
}
