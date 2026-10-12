import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../widgets.dart';

/// What the sample deal completes.
enum SampleCompletes {
  nothing('Nothing'),
  game('A game'),
  rubberTwoNil('A rubber 2–0'),
  rubberTwoOne('A rubber 2–1');

  const SampleCompletes(this.label);
  final String label;
}

/// The inputs of the sample calculator. The declarer sits South, so the
/// declaring side is N-S ("Declarers") and E-W are the "Defenders".
class SampleDeal {
  const SampleDeal({
    this.level = 4,
    this.strain = Strain.spades,
    this.doubling = Doubling.none,
    this.vulnerable = false,
    this.tricksTaken = 10,
    this.honorsSide,
    this.holding,
    this.completes = SampleCompletes.nothing,
  });

  final int level;
  final Strain strain;
  final Doubling doubling;
  final bool vulnerable;
  final int tricksTaken;
  final Side? honorsSide;
  final HonorsHolding? holding;
  final SampleCompletes completes;

  SampleDeal copyWith({
    int? level,
    Strain? strain,
    Doubling? doubling,
    bool? vulnerable,
    int? tricksTaken,
    Side? Function()? honorsSide,
    HonorsHolding? Function()? holding,
    SampleCompletes? completes,
  }) => SampleDeal(
    level: level ?? this.level,
    strain: strain ?? this.strain,
    doubling: doubling ?? this.doubling,
    vulnerable: vulnerable ?? this.vulnerable,
    tricksTaken: tricksTaken ?? this.tricksTaken,
    honorsSide: honorsSide == null ? this.honorsSide : honorsSide(),
    holding: holding == null ? this.holding : holding(),
    completes: completes ?? this.completes,
  );

  DealResult get result => DealResult(
    contract: Contract(
      bid: Bid(level, strain),
      doubling: doubling,
      declarer: Seat.south,
    ),
    tricksTaken: tricksTaken,
    honors: holding == null
        ? null
        : holding!.isNone
        ? Honors.none
        : Honors(holding!, honorsSide ?? Side.northSouth),
  );
}

/// Scores [deal] with [values], with the same [DealScorer] as a session.
/// Game and rubber bonuses come from the "completes" input.
List<ScoreItem> scoreSample(SampleDeal deal, ScoringValues values) {
  final result = deal.result;
  final vul = Vulnerability(northSouth: deal.vulnerable, eastWest: false);
  final items = [
    ...DealScorer.score(result, vul, values, const ScoringComponents()).items,
  ];
  if (result.isFulfilled && deal.completes != SampleCompletes.nothing) {
    void add(ScoreComponent c, int points) {
      if (points != 0) items.add(ScoreItem(Side.northSouth, c, points));
    }

    add(
      ScoreComponent.gameBonus,
      values[deal.vulnerable
          ? ScoringField.gameBonusVulnerable
          : ScoringField.gameBonusNotVulnerable],
    );
    if (deal.completes == SampleCompletes.rubberTwoNil) {
      add(ScoreComponent.rubberBonus, values[ScoringField.rubberTwoNil]);
    } else if (deal.completes == SampleCompletes.rubberTwoOne) {
      add(ScoreComponent.rubberBonus, values[ScoringField.rubberTwoOne]);
    }
  }
  return items;
}

class SampleCalculator extends StatefulWidget {
  const SampleCalculator({super.key, required this.houseValues});

  /// The values on the screen, or null when a value is not valid.
  final ScoringValues? houseValues;

  @override
  State<SampleCalculator> createState() => _SampleCalculatorState();
}

class _SampleCalculatorState extends State<SampleCalculator> {
  SampleDeal deal = const SampleDeal();

  static const Map<Side, String> sideNames = {
    Side.northSouth: 'Declarers',
    Side.eastWest: 'Defenders',
  };

  void update(SampleDeal d) => setState(() {
    final holdings = HonorsHolding.forStrain(d.strain);
    final holding = holdings.contains(d.holding) ? d.holding : null;
    final maxTricks = 13;
    deal = d.copyWith(
      holding: () => holding,
      tricksTaken: d.tricksTaken.clamp(0, maxTricks),
    );
  });

  @override
  Widget build(BuildContext context) {
    final options = ResultOption.forLevel(deal.level);
    final selected = options.firstWhere(
      (o) => o.tricksTaken == deal.tricksTaken,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<int>(
              key: const Key('calc-level'),
              value: deal.level,
              items: [
                for (var l = 1; l <= 7; l++)
                  DropdownMenuItem(value: l, child: Text('$l')),
              ],
              onChanged: (l) =>
                  update(deal.copyWith(level: l, tricksTaken: l! + 6)),
            ),
            DropdownButton<Strain>(
              key: const Key('calc-strain'),
              value: deal.strain,
              items: [
                for (final s in Strain.values)
                  DropdownMenuItem(value: s, child: SuitText(s.symbol)),
              ],
              onChanged: (s) => update(deal.copyWith(strain: s)),
            ),
            DropdownButton<Doubling>(
              key: const Key('calc-doubling'),
              value: deal.doubling,
              items: const [
                DropdownMenuItem(
                  value: Doubling.none,
                  child: Text('Undoubled'),
                ),
                DropdownMenuItem(
                  value: Doubling.doubled,
                  child: Text('Doubled'),
                ),
                DropdownMenuItem(
                  value: Doubling.redoubled,
                  child: Text('Redoubled'),
                ),
              ],
              onChanged: (d) => update(deal.copyWith(doubling: d)),
            ),
            FilterChip(
              key: const Key('calc-vul'),
              label: const Text('Vulnerable'),
              selected: deal.vulnerable,
              onSelected: (v) => update(deal.copyWith(vulnerable: v)),
            ),
            DropdownButton<int>(
              key: const Key('calc-result'),
              value: selected.tricksTaken,
              items: [
                for (final o in options)
                  DropdownMenuItem(value: o.tricksTaken, child: Text(o.label)),
              ],
              onChanged: (t) => update(deal.copyWith(tricksTaken: t)),
            ),
            SizedBox(
              width: double.infinity,
              child: DropdownButton<HonorsHolding?>(
                isExpanded: true,
                key: const Key('calc-honors'),
                value: deal.holding,
                hint: const Text('No honors'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No honors')),
                  for (final h in HonorsHolding.forStrain(deal.strain))
                    DropdownMenuItem(value: h, child: Text(h.label)),
                ],
                onChanged: (h) => update(deal.copyWith(holding: () => h)),
              ),
            ),
            if (deal.holding != null && !deal.holding!.isNone)
              SizedBox(
                width: double.infinity,
                child: DropdownButton<Side>(
                  isExpanded: true,
                  key: const Key('calc-honors-side'),
                  value: deal.honorsSide ?? Side.northSouth,
                  items: [
                    for (final s in Side.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text('Held by ${sideNames[s]}'),
                      ),
                  ],
                  onChanged: (s) => update(deal.copyWith(honorsSide: () => s)),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: DropdownButton<SampleCompletes>(
                isExpanded: true,
                key: const Key('calc-completes'),
                value: deal.completes,
                items: [
                  for (final c in SampleCompletes.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text('Completes: ${c.label}'),
                    ),
                ],
                onChanged: (c) => update(deal.copyWith(completes: c)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.houseValues == null)
          const Text(
            'The calculator cannot calculate until each value is corrected.',
            key: Key('calc-invalid'),
          )
        else
          _ResultTable(
            deal: deal,
            house: scoreSample(deal, widget.houseValues!),
            standard: scoreSample(deal, ScoringValues.standard()),
          ),
      ],
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({
    required this.deal,
    required this.house,
    required this.standard,
  });

  final SampleDeal deal;
  final List<ScoreItem> house;
  final List<ScoreItem> standard;

  @override
  Widget build(BuildContext context) {
    final rows = <(Side, ScoreComponent)>{
      for (final i in [...house, ...standard]) (i.side, i.component),
    }.toList();
    int sum(List<ScoreItem> items, Side side, [ScoreComponent? c]) => items
        .where((i) => i.side == side && (c == null || i.component == c))
        .fold(0, (s, i) => s + i.points);
    String who(Side s) => s == Side.northSouth ? 'Declarers' : 'Defenders';
    final style = Theme.of(context).textTheme.bodyMedium;
    final bold = style?.copyWith(fontWeight: FontWeight.w600);
    TableRow row(String label, String a, String b, {TextStyle? s}) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: s),
        ),
        Text(a, textAlign: TextAlign.end, style: s),
        Text(b, textAlign: TextAlign.end, style: s),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(deal.result.fullResult, key: const Key('calc-full-result')),
        const SizedBox(height: 8),
        Table(
          key: const Key('calc-table'),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.4),
            2: FlexColumnWidth(1.4),
          },
          children: [
            row('', 'House', 'Standard', s: bold),
            for (final (side, c) in rows)
              row(
                '${c.label} (${who(side)})',
                '${sum(house, side, c)}',
                '${sum(standard, side, c)}',
              ),
            for (final side in Side.values)
              row(
                'Total ${who(side)}',
                '${sum(house, side)}',
                '${sum(standard, side)}',
                s: bold,
              ),
          ],
        ),
      ],
    );
  }
}
