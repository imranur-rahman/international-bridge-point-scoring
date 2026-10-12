import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auction/auction.dart';
import '../../../core/core.dart';
import '../../../session/session.dart';
import '../theme.dart';
import '../widgets.dart';
import 'deal_screen.dart';

class AuctionView extends ConsumerWidget {
  const AuctionView({super.key, required this.session, required this.draft});

  final SessionState session;
  final DealDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auction = draft.auction!;
    final players = session.settings.players;
    final legal = auction.legalCalls();
    void call(Call c) => sendCommand(context, ref, RecordCall(c));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuctionTable(auction: auction, players: players),
        const SizedBox(height: 12),
        Text(
          auctionStatus(auction, players),
          key: const Key('auction-status'),
          style: valueStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        AuctionHistory(auction: auction, players: players),
        const SizedBox(height: 16),
        BiddingBox(legal: legal, onCall: call),
        const SizedBox(height: 8),
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
            OutlinedButton.icon(
              key: const Key('undo-call'),
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
              onPressed: auction.calls.isEmpty
                  ? null
                  : () => sendCommand(context, ref, const UndoCall()),
            ),
          ],
        ),
      ],
    );
  }
}

/// The four players in their seats around a table. North is at the top.
class AuctionTable extends StatelessWidget {
  const AuctionTable({super.key, required this.auction, required this.players});

  final Auction auction;
  final Players players;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget seat(Seat s) {
      final turn = auction.toCall == s;
      final dealer = auction.dealer == s;
      return Container(
        key: Key('seat-${s.name}'),
        constraints: const BoxConstraints(minWidth: 72, maxWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: turn ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              players.nameOf(s),
              key: turn ? const Key('turn') : null,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: turn ? scheme.onPrimary : scheme.onSurface,
                fontWeight: turn ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            Text(
              dealer ? '${s.label} · Dealer' : s.label,
              key: dealer ? const Key('dealer-mark') : null,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: turn ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const Key('auction-table'),
      children: [
        seat(Seat.north),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: seat(Seat.west)),
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Flexible(child: seat(Seat.east)),
          ],
        ),
        const SizedBox(height: 8),
        seat(Seat.south),
      ],
    );
  }
}

/// The calls of the auction in a grid with one column for each seat.
class AuctionHistory extends StatelessWidget {
  const AuctionHistory({
    super.key,
    required this.auction,
    required this.players,
  });

  final Auction auction;
  final Players players;

  @override
  Widget build(BuildContext context) {
    final rows = auction.rounds();
    final header = Theme.of(context).textTheme.labelMedium;
    return Table(
      key: const Key('auction-history'),
      children: [
        TableRow(
          children: [
            for (final s in Auction.columnOrder)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  s.letter,
                  textAlign: TextAlign.center,
                  style: header,
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (final c in row)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SuitText(
                    c?.toString() ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Levels 1 to 7 × five denominations, plus Pass, Double, and Redouble.
/// Calls that are not legal are disabled.
class BiddingBox extends StatelessWidget {
  const BiddingBox({super.key, required this.legal, required this.onCall});

  final Set<Call> legal;
  final ValueChanged<Call> onCall;

  @override
  Widget build(BuildContext context) {
    Widget button(Call c, Widget label, Key key) => Padding(
      padding: const EdgeInsets.all(2),
      child: OutlinedButton(
        key: key,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 2),
        ),
        onPressed: legal.contains(c) ? () => onCall(c) : null,
        child: FittedBox(child: label),
      ),
    );
    return Column(
      key: const Key('bidding-box'),
      children: [
        for (var level = 1; level <= 7; level++)
          Row(
            children: [
              for (final strain in Strain.values)
                Expanded(
                  child: button(
                    Call.bid(Bid(level, strain)),
                    SuitText(Bid(level, strain).toString()),
                    Key('bid-${Bid(level, strain).toJson()}'),
                  ),
                ),
            ],
          ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: button(Call.pass, const Text('Pass'), const Key('call-P')),
            ),
            Expanded(
              child: button(Call.double, const Text('X'), const Key('call-X')),
            ),
            Expanded(
              child: button(
                Call.redouble,
                const Text('XX'),
                const Key('call-XX'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
