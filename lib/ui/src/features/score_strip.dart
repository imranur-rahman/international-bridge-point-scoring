import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../scoring/scoring.dart';
import '../providers.dart';

/// The state of the game at the top of the deal screen on a phone: the
/// total, the games, the points below the line, and the points needed for a
/// game, for each side. A tap opens the score sheet.
class ScoreStrip extends ConsumerWidget {
  const ScoreStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final ledger = ref.watch(ledgerProvider);
    if (session == null || ledger == null) return const SizedBox.shrink();
    final players = session.settings.players;
    final scheme = Theme.of(context).colorScheme;
    final threshold = ledger.values[ScoringField.gameThreshold];
    return Material(
      key: const Key('score-strip'),
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/sheet'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              for (final side in Side.values)
                _SideRow(
                  key: Key('strip-${side.name}'),
                  name: players.partnershipName(side),
                  total: ledger.totalFor(side),
                  games: ledger.games[side]!,
                  below: ledger.partScores[side]!,
                  needed: (threshold - ledger.partScores[side]!).clamp(
                    1,
                    threshold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({
    super.key,
    required this.name,
    required this.total,
    required this.games,
    required this.below,
    required this.needed,
  });

  final String name;
  final int total;
  final int games;
  final int below;
  final int needed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    Widget fitted(String text, {TextStyle? style, Key? key}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, key: key, style: style, maxLines: 1),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: fitted(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: fitted(
              '$total',
              key: const Key('strip-total'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: fitted(
              'G $games',
              key: const Key('strip-games'),
              style: small,
            ),
          ),
          Expanded(
            flex: 3,
            child: fitted(
              '$below below',
              key: const Key('strip-below'),
              style: small,
            ),
          ),
          Expanded(
            flex: 5,
            child: fitted(
              'needs $needed for game',
              key: const Key('strip-needs'),
              style: small?.copyWith(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
