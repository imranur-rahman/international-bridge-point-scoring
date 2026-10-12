import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../install/install_prompt.dart';
import '../providers.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  InstallState install = InstallState.none;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _check();
    // The browser can offer its install prompt after the first frame, so
    // check again every 2 seconds, for up to 10 seconds.
    var ticks = 0;
    _poll = Timer.periodic(const Duration(seconds: 2), (timer) {
      ticks++;
      _check();
      if (install != InstallState.none || ticks >= 5) timer.cancel();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _check() {
    final state = ref.read(installPromptProvider).state();
    if (state != install && mounted) setState(() => install = state);
  }

  Future<void> _install() async {
    if (install == InstallState.ios) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('ios-install-guide'),
          title: const Text('Install IB Scoring'),
          content: const Text(
            'Tap Share, then Add to Home Screen. The app then opens from '
            'your home screen and works offline.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    try {
      await ref.read(installPromptProvider).install();
    } on Object {
      // The browser can refuse the prompt, for example without a user tap.
    } finally {
      _check();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final ledger = ref.watch(ledgerProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('IB Scoring'),
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
          Text(
            'International Bridge Scoring',
            key: const Key('home-heading'),
            style: text.headlineSmall,
          ),
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
          if (install == InstallState.prompt ||
              install == InstallState.ios) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const Key('install'),
              icon: const Icon(Icons.install_mobile),
              label: const Text('Install IB Scoring'),
              onPressed: _install,
            ),
          ],
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
