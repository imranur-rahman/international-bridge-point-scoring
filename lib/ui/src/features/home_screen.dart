import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../providers.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final ledger = ref.watch(ledgerProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bridge Score'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ScrollPage(
        children: [
          Text('Rubber bridge scoring', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Keep the score of each deal by the rules.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (session != null && ledger != null) ...[
            FilledButton.icon(
              key: const Key('continue'),
              icon: Icon(session.isEnded ? Icons.flag : Icons.play_arrow),
              label: const Text('Continue session'),
              onPressed: () =>
                  context.go(session.isEnded ? '/summary' : '/deal'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                session.isEnded
                    ? 'Session ended · ${session.records.length} deals'
                    : 'Deal ${session.currentDealNumber} · '
                          '${session.settings.players.partnershipName(Side.northSouth)} '
                          '${ledger.totalFor(Side.northSouth)} · '
                          '${session.settings.players.partnershipName(Side.eastWest)} '
                          '${ledger.totalFor(Side.eastWest)}',
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            key: const Key('new-session'),
            icon: const Icon(Icons.add),
            label: const Text('New session'),
            onPressed: () async {
              if (session != null && !session.isEnded) {
                final ok = await confirm(
                  context,
                  title: 'End the active session?',
                  message:
                      'A new session ends the active session and moves it '
                      'to the past sessions.',
                  action: 'End and continue',
                );
                if (!ok) return;
              }
              if (context.mounted) context.go('/setup');
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('past-sessions'),
            icon: const Icon(Icons.history),
            label: const Text('Past sessions'),
            onPressed: () => context.push('/past'),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 24),
            Text(
              'Your sessions stay only in this browser on this device. '
              'Cleared site data or a private window removes them.',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
