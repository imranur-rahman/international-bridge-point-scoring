import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';
import 'deal_screen.dart';

/// One screen for the contract, the declarer, the result, and the honors
/// of a deal (the "Quick-entry screen" requirement).
///
/// The inputs stay in this widget until "Score deal" sends one command, so
/// a reload shows an empty screen (design decision D3).
class QuickEntryView extends ConsumerStatefulWidget {
  const QuickEntryView({super.key, required this.session, required this.draft});

  final SessionState session;
  final DealDraft draft;

  @override
  ConsumerState<QuickEntryView> createState() => _QuickEntryViewState();
}

class _QuickEntryViewState extends ConsumerState<QuickEntryView> {
  ContractInput input = const ContractInput();
  int? tricks;
  Honors? honors;

  bool get honorsOn => widget.session.settings.components.honors;

  DealResult? get result {
    final c = input.toContract();
    final t = tricks;
    if (c == null || t == null) return null;
    if (honorsOn && honors == null) return null;
    return DealResult(contract: c, tricksTaken: t, honors: honors);
  }

  void setLevel(int level) => setState(() {
    if (input.level != level) tricks = null;
    input = _copy(level: level);
  });

  void setStrain(Strain strain) => setState(() {
    final old = input.strain;
    if (old != null && old.isSuit != strain.isSuit) honors = null;
    input = _copy(strain: strain);
  });

  ContractInput _copy({
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

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final draft = widget.draft;
    final p = session.settings.players;
    final vul = ref.watch(ledgerProvider)!.nextVulnerability;
    final text = Theme.of(context).textTheme;
    final declarer = input.declarer;
    final contract = input.toContract();
    final r = tricks == null || contract == null
        ? null
        : DealResult(contract: contract, tricksTaken: tricks!);

    Widget chips<T>(
      String keyPrefix,
      List<T> values,
      T? selected,
      Widget Function(T) label,
      String Function(T) keyOf,
      void Function(T) onSelected,
    ) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            key: Key('$keyPrefix-${keyOf(v)}'),
            label: label(v),
            selected: v == selected,
            onSelected: (_) => onSelected(v),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Deal ${session.currentDealNumber}', style: text.headlineSmall),
        const SizedBox(height: 4),
        Text('Dealer: ${p.nameOf(draft.dealer)} (${draft.dealer.label})'),
        const SizedBox(height: 8),
        for (final side in Side.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: VulnerabilityLabel(
              name: p.partnershipName(side),
              vulnerable: vul.of(side),
            ),
          ),
        const SectionTitle('Contract'),
        chips<int>(
          'quick-level',
          [1, 2, 3, 4, 5, 6, 7],
          input.level,
          (l) => Text('$l'),
          (l) => '$l',
          setLevel,
        ),
        const SizedBox(height: 8),
        chips<Strain>(
          'quick-strain',
          Strain.values,
          input.strain,
          (s) => SuitText(s.symbol),
          (s) => s.name,
          setStrain,
        ),
        const SizedBox(height: 8),
        chips<Doubling>(
          'quick-doubling',
          Doubling.values,
          input.doubling,
          (d) => Text(switch (d) {
            Doubling.none => 'Undoubled',
            Doubling.doubled => 'Doubled',
            Doubling.redoubled => 'Redoubled',
          }),
          (d) => d.name,
          (d) => setState(() => input = _copy(doubling: d)),
        ),
        const SectionTitle('Declarer'),
        chips<Seat>(
          'quick-declarer',
          Seat.values,
          declarer,
          (s) => Text('${p.nameOf(s)} (${s.letter})'),
          (s) => s.name,
          (s) => setState(() => input = _copy(declarer: s)),
        ),
        if (declarer != null) ...[
          const SizedBox(height: 8),
          _Roles(roles: PlayRoles.of(declarer), players: p),
        ],
        if (contract != null) ...[
          const SizedBox(height: 12),
          ContractHeadline(contract: contract, players: p),
        ],
        if (input.level != null) ...[
          const SectionTitle('Result'),
          ResultPicker(
            key: ValueKey('quick-result-${input.level}'),
            level: input.level!,
            selected: tricks,
            onSelected: (t) => setState(() => tricks = t),
          ),
          const SizedBox(height: 8),
          Text(
            r?.fullResult ?? 'Select the result',
            key: const Key('quick-full-result'),
            style: valueStyle(context)?.copyWith(
              color: r == null
                  ? null
                  : ResultColors.of(
                      Theme.of(context).colorScheme,
                      r.difference,
                    ).selected,
            ),
          ),
        ],
        if (honorsOn && input.strain != null) ...[
          const SectionTitle('Honors'),
          HonorsPicker(
            key: ValueKey('quick-honors-${input.strain!.isSuit}'),
            strain: input.strain!,
            players: p,
            values: session.settings.values,
            honors: honors,
            onChanged: (h) => setState(() => honors = h),
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
              key: const Key('quick-pass-out'),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Passed out?',
                  message: 'All four players passed. The deal scores 0.',
                  action: 'Passed out',
                );
                if (ok && context.mounted) {
                  await sendCommand(context, ref, const RecordQuickDeal(null));
                }
              },
              child: const Text('Passed out'),
            ),
            FilledButton(
              key: const Key('quick-score'),
              onPressed: result == null
                  ? null
                  : () => sendCommand(context, ref, RecordQuickDeal(result)),
              child: const Text('Score deal'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The dummy and the opening leader, once the declarer is known.
class _Roles extends StatelessWidget {
  const _Roles({required this.roles, required this.players});

  final PlayRoles roles;
  final Players players;

  @override
  Widget build(BuildContext context) {
    Widget line(String label, Seat seat, Key key) => Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(
          child: Text(
            '${players.nameOf(seat)} (${seat.label})',
            key: key,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            line('Dummy', roles.dummy, const Key('quick-dummy')),
            const SizedBox(height: 4),
            line('Opening lead', roles.openingLeader, const Key('quick-lead')),
          ],
        ),
      ),
    );
  }
}
