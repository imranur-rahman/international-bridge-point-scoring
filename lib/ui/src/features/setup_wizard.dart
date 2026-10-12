import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../../../session/session.dart';
import '../providers.dart';
import '../widgets.dart';

/// Settings to fill in the setup wizard, for "New session, same players".
class SetupPrefillNotifier extends Notifier<SessionSettings?> {
  @override
  SessionSettings? build() => null;

  void set(SessionSettings? settings) => state = settings;
}

final setupPrefillProvider =
    NotifierProvider<SetupPrefillNotifier, SessionSettings?>(
      SetupPrefillNotifier.new,
    );

enum EndRuleType { deals, target }

class SetupWizard extends ConsumerStatefulWidget {
  const SetupWizard({super.key});

  @override
  ConsumerState<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends ConsumerState<SetupWizard> {
  static const List<String> stepNames = ['Players', 'Game rules', 'Scoring'];

  int step = 0;
  final Map<Seat, TextEditingController> names = {
    for (final seat in Seat.values) seat: TextEditingController(),
  };
  Map<Seat, String> nameErrors = {};
  Seat firstDealer = Seat.north;

  EndRuleType endRuleType = EndRuleType.deals;
  final TextEditingController deals = TextEditingController(
    text: '${DealCountRule.defaultDeals}',
  );
  final TextEditingController target = TextEditingController(text: '3000');
  String? endRuleError;
  bool biddingStep = false;
  bool honors = true;
  bool unfinishedBonus = true;

  late ScoringPreset preset;

  @override
  void initState() {
    super.initState();
    preset = ref.read(lastPresetProvider);
    final prefill = ref.read(setupPrefillProvider);
    if (prefill != null) {
      for (final seat in Seat.values) {
        names[seat]!.text = prefill.players.nameOf(seat);
      }
      firstDealer = prefill.firstDealer;
      switch (prefill.endRule) {
        case DealCountRule(:final deals):
          endRuleType = EndRuleType.deals;
          this.deals.text = '$deals';
        case TargetScoreRule(:final points):
          endRuleType = EndRuleType.target;
          target.text = '$points';
      }
      biddingStep = prefill.biddingStep;
      honors = prefill.components.honors;
      unfinishedBonus = prefill.components.unfinishedRubberBonus;
      preset = prefill.preset;
    }
  }

  @override
  void dispose() {
    for (final c in names.values) {
      c.dispose();
    }
    deals.dispose();
    target.dispose();
    super.dispose();
  }

  Map<Seat, String> get rawNames => {
    for (final seat in Seat.values) seat: names[seat]!.text,
  };

  String partnership(Side side) {
    final a = names[side.seats[0]]!.text.trim();
    final b = names[side.seats[1]]!.text.trim();
    return '${a.isEmpty ? '…' : a} & ${b.isEmpty ? '…' : b}';
  }

  EndRule? parseEndRule() {
    final raw = (endRuleType == EndRuleType.deals ? deals : target).text.trim();
    final value = int.tryParse(raw);
    if (value == null) return null;
    return endRuleType == EndRuleType.deals
        ? DealCountRule(value)
        : TargetScoreRule(value);
  }

  bool validateStep() {
    setState(() {
      if (step == 0) {
        nameErrors = Players.validate(rawNames);
      } else if (step == 1) {
        final rule = parseEndRule();
        endRuleError = rule == null ? 'Enter a whole number' : rule.validate();
      }
    });
    return step == 0
        ? nameErrors.isEmpty
        : step == 1
        ? endRuleError == null
        : true;
  }

  Future<void> startSession() async {
    final settings = SessionSettings(
      players: Players(rawNames),
      firstDealer: firstDealer,
      endRule: parseEndRule()!,
      biddingStep: biddingStep,
      components: ScoringComponents(
        honors: honors,
        unfinishedRubberBonus: unfinishedBonus,
      ),
      preset: preset,
      values: valuesOf(preset, ref.read(houseRulesProvider)),
    );
    await ref.read(sessionProvider.notifier).start(settings);
    ref.read(setupPrefillProvider.notifier).set(null);
    if (mounted) context.go('/deal');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New session'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ScrollPage(
        children: [
          Text(
            'Step ${step + 1} of 3 · ${stepNames[step]}',
            key: const Key('step-title'),
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < stepNames.length; i++)
                Chip(
                  label: Text('${i + 1}. ${stepNames[i]}'),
                  backgroundColor: i == step
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...switch (step) {
            0 => playersStep(),
            1 => rulesStep(),
            _ => scoringStep(),
          },
          const SizedBox(height: 24),
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              if (step > 0)
                OutlinedButton.icon(
                  key: const Key('back'),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Back'),
                  onPressed: () => setState(() => step--),
                )
              else
                const SizedBox.shrink(),
              if (step < 2)
                FilledButton.icon(
                  key: const Key('next'),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                  onPressed: () {
                    if (validateStep()) setState(() => step++);
                  },
                )
              else
                FilledButton.icon(
                  key: const Key('start'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start session'),
                  onPressed: startSession,
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> playersStep() => [
    const SectionTitle('Players'),
    for (final seat in Seat.values)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          key: Key('name-${seat.name}'),
          controller: names[seat],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Player ${seat.index + 1} · ${seat.label}',
            border: const OutlineInputBorder(),
            errorText: nameErrors[seat],
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    const SectionTitle('Partnerships'),
    Text(partnership(Side.northSouth), key: const Key('pair-ns')),
    const SizedBox(height: 4),
    Text(partnership(Side.eastWest), key: const Key('pair-ew')),
    const SectionTitle('First dealer'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final seat in Seat.values)
          ChoiceChip(
            key: Key('dealer-${seat.name}'),
            label: Text(seat.label),
            selected: firstDealer == seat,
            onSelected: (_) => setState(() => firstDealer = seat),
          ),
      ],
    ),
  ];

  List<Widget> rulesStep() => [
    const SectionTitle('End rule'),
    RadioGroup<EndRuleType>(
      groupValue: endRuleType,
      onChanged: (v) => setState(() {
        endRuleType = v!;
        endRuleError = null;
      }),
      child: const Column(
        children: [
          RadioListTile<EndRuleType>(
            key: Key('rule-deals'),
            value: EndRuleType.deals,
            contentPadding: EdgeInsets.zero,
            title: Text('Number of deals'),
          ),
          RadioListTile<EndRuleType>(
            key: Key('rule-target'),
            value: EndRuleType.target,
            contentPadding: EdgeInsets.zero,
            title: Text('Target score'),
          ),
        ],
      ),
    ),
    TextField(
      key: const Key('rule-value'),
      controller: endRuleType == EndRuleType.deals ? deals : target,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: endRuleType == EndRuleType.deals
            ? 'Deals (1 to 200)'
            : 'Target points (100 to 100000)',
        border: const OutlineInputBorder(),
        errorText: endRuleError,
      ),
    ),
    const SectionTitle('Options'),
    SwitchListTile(
      key: const Key('bidding'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Bidding step'),
      subtitle: const Text('Record the calls of each auction'),
      value: biddingStep,
      onChanged: (v) => setState(() => biddingStep = v),
    ),
    SwitchListTile(
      key: const Key('honors'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Honors'),
      value: honors,
      onChanged: (v) => setState(() => honors = v),
    ),
    SwitchListTile(
      key: const Key('unfinished'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Unfinished rubber bonus'),
      value: unfinishedBonus,
      onChanged: (v) => setState(() => unfinishedBonus = v),
    ),
  ];

  List<Widget> scoringStep() => [
    const SectionTitle('Scoring values'),
    RadioGroup<ScoringPreset>(
      groupValue: preset,
      onChanged: (v) => setState(() => preset = v!),
      child: Column(
        children: [
          for (final p in ScoringPreset.values)
            RadioListTile<ScoringPreset>(
              key: Key('preset-${p.name}'),
              value: p,
              contentPadding: EdgeInsets.zero,
              title: Text(p.label),
              subtitle: Text(
                p == ScoringPreset.standard
                    ? 'The values of the Laws of Contract Bridge'
                    : 'Your own values, saved on this device',
              ),
              secondary: IconButton(
                key: Key('open-${p.name}'),
                tooltip: p == ScoringPreset.standard
                    ? 'View Standard'
                    : 'Change House rules',
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    context.push('/setup/house-rules?preset=${p.name}'),
              ),
            ),
        ],
      ),
    ),
  ];
}
