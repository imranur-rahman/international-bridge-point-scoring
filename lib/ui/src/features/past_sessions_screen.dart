import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../session/session.dart';
import '../providers.dart';
import '../widgets.dart';

class PastSessionsScreen extends ConsumerWidget {
  const PastSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final past = ref.watch(pastSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Past sessions')),
      body: past.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Cannot read the past sessions: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No past sessions.'));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final e in entries)
                PageFrame(
                  child: Card(
                    key: Key('past-${e.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.title ?? 'Cannot be opened'),
                      subtitle: Text(_subtitle(e.session, e.date)),
                      enabled: e.readable,
                      onTap: e.readable
                          ? () => context.push('/past/${e.id}')
                          : null,
                      trailing: IconButton(
                        key: Key('delete-${e.id}'),
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            title: 'Delete this session?',
                            message:
                                'The app removes the session from this '
                                'device. You cannot undo this.',
                            action: 'Delete',
                          );
                          if (!ok) return;
                          await ref
                              .read(sessionRepositoryProvider)
                              .deletePast(e.id);
                          ref.invalidate(pastSessionsProvider);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _subtitle(SessionState? session, DateTime? date) {
    if (session == null) return 'The stored data cannot be read.';
    final ledger = session.ledger;
    final p = session.settings.players;
    final ns = ledger.finalTotalFor(Side.northSouth);
    final ew = ledger.finalTotalFor(Side.eastWest);
    final winner = ns == ew
        ? 'Tie'
        : 'Winner: ${p.partnershipName(ns > ew ? Side.northSouth : Side.eastWest)}';
    final d = date?.toLocal();
    final day = d == null
        ? ''
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')} · ';
    return '$day$ns – $ew · $winner';
  }
}
