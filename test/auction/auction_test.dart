import 'dart:math';

import 'package:bridge_scorekeeper/auction/auction.dart';
import 'package:bridge_scorekeeper/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

Call b(String code) => Call.fromJson(code);

Auction play(Seat dealer, List<String> codes) =>
    Auction.fromCalls(dealer, codes.map(b));

void main() {
  group('Turn order', () {
    test('the dealer calls first', () {
      expect(Auction.start(Seat.east).toCall, Seat.east);
    });

    test('clockwise turns', () {
      final a = play(Seat.south, ['P']);
      expect(a.toCall, Seat.west);
    });
  });

  group('Call history', () {
    test('history grid', () {
      final a = play(Seat.north, ['1C', 'P']);
      final rows = a.rounds();
      expect(rows, hasLength(1));
      // Columns: W, N, E, S.
      expect(rows.first[0], isNull);
      expect(rows.first[1], b('1C'));
      expect(rows.first[2], Call.pass);
      expect(rows.first[3], isNull);
    });

    test('grid wraps to a new round after South', () {
      final a = play(Seat.south, ['1H', 'P', '2H', 'P']);
      final rows = a.rounds();
      expect(rows, hasLength(2));
      expect(rows[0][3], b('1H'));
      expect(rows[1][0], Call.pass);
      expect(rows[1][1], b('2H'));
    });
  });

  group('Legal bids only', () {
    test('lower bid is not legal', () {
      final a = play(Seat.north, ['2H']);
      final legal = a.legalCalls();
      for (final bid in Bid.all) {
        final expected = bid.isHigherThan(Bid(2, Strain.hearts));
        expect(legal.contains(Call.bid(bid)), expected, reason: '$bid');
      }
      expect(a.isLegal(b('2S')), isTrue);
      expect(() => a.add(b('1C')), throwsA(isA<IllegalCallException>()));
    });

    test('pass is always legal during the auction', () {
      expect(Auction.start(Seat.north).isLegal(Call.pass), isTrue);
    });
  });

  group('Legal double and redouble', () {
    test('double of partner\'s bid', () {
      final a = play(Seat.north, ['1S', 'P']);
      expect(a.toCall, Seat.south);
      expect(a.isLegal(Call.double), isFalse);
    });

    test('double of opponent\'s bid', () {
      final a = play(Seat.north, ['1S']);
      expect(a.toCall, Seat.east);
      expect(a.isLegal(Call.double), isTrue);
    });

    test('double after a pass of the partner of the bidder', () {
      final a = play(Seat.north, ['1S', 'P', 'P']);
      expect(a.toCall, Seat.west);
      expect(a.isLegal(Call.double), isTrue);
    });

    test('redouble after double', () {
      final a = play(Seat.north, ['1S', 'X']);
      expect(a.toCall, Seat.south);
      expect(a.isLegal(Call.redouble), isTrue);
    });

    test('second double is not legal', () {
      final a = play(Seat.north, ['1S', 'X', 'P']);
      expect(a.toCall, Seat.west);
      expect(a.isLegal(Call.double), isFalse);
    });

    test('no double or redouble at the start', () {
      final a = Auction.start(Seat.north);
      expect(a.isLegal(Call.double), isFalse);
      expect(a.isLegal(Call.redouble), isFalse);
    });

    test('doubler side cannot redouble its own double', () {
      final a = play(Seat.north, ['1S', 'X', 'P', 'P']);
      expect(a.toCall, Seat.north);
      expect(a.isLegal(Call.redouble), isTrue);
      final b2 = play(Seat.north, ['1S', 'X', 'P']);
      expect(b2.toCall, Seat.west);
      expect(b2.isLegal(Call.redouble), isFalse);
    });
  });

  group('End of auction', () {
    test('contract reached', () {
      final a = play(Seat.north, ['1N', 'P', '3N', 'P', 'P', 'P']);
      final outcome = a.outcome as ContractReached;
      expect(outcome.contract.bid, Bid(3, Strain.noTrump));
      expect(a.toCall, isNull);
      expect(a.legalCalls(), isEmpty);
    });

    test('passed out', () {
      final a = play(Seat.east, ['P', 'P', 'P', 'P']);
      expect(a.outcome, isA<PassedOut>());
    });

    test('three passes at the start do not end the auction', () {
      final a = play(Seat.east, ['P', 'P', 'P']);
      expect(a.outcome, isA<InProgress>());
      final after = a.add(b('1C')).add(Call.pass).add(Call.pass).add(Call.pass);
      expect((after.outcome as ContractReached).contract.declarer, Seat.north);
    });

    test('no call after the end', () {
      final a = play(Seat.east, ['P', 'P', 'P', 'P']);
      expect(() => a.add(Call.pass), throwsA(isA<IllegalCallException>()));
    });
  });

  group('Final contract and declarer', () {
    test('declarer is first to name the denomination', () {
      final a = play(Seat.north, ['1H', 'P', '4H', 'P', 'P', 'P']);
      final c = (a.outcome as ContractReached).contract;
      expect(c.bid, Bid(4, Strain.hearts));
      expect(c.declarer, Seat.north);
      expect(c.doubling, Doubling.none);
    });

    test('doubled contract', () {
      final a = play(Seat.west, ['2S', 'X', 'P', 'P', 'P']);
      final c = (a.outcome as ContractReached).contract;
      expect(c.toString(), '2♠X');
      expect(c.declarer, Seat.west);
    });

    test('redoubled contract', () {
      final a = play(Seat.west, ['2S', 'X', 'XX', 'P', 'P', 'P']);
      expect(
        (a.outcome as ContractReached).contract.doubling,
        Doubling.redoubled,
      );
    });

    test('double cancelled by a new bid', () {
      final a = play(Seat.north, ['1S', 'X', '2S', 'P', 'P', 'P']);
      final c = (a.outcome as ContractReached).contract;
      expect(c.bid, Bid(2, Strain.spades));
      expect(c.doubling, Doubling.none);
      expect(c.declarer, Seat.north);
    });

    test('strain named by the opponents first does not count', () {
      // East bids spades first, then N-S win the auction in spades.
      final a = play(Seat.north, ['1H', '1S', 'P', 'P', '2S', 'P', 'P', 'P']);
      // N opens 1H, E 1S, S P, W P, N 2S (cue), E P, S P, W P.
      final c = (a.outcome as ContractReached).contract;
      expect(c.declarer, Seat.north);
    });
  });

  group('Undo last call', () {
    test('undo a mistaken call', () {
      final a = play(Seat.north, ['1C']).add(b('3D'));
      expect(a.toCall, Seat.south);
      final undone = a.undo();
      expect(undone.calls, [b('1C')]);
      expect(undone.toCall, Seat.east);
    });

    test('undo after the end reopens the auction', () {
      final a = play(Seat.north, ['1C', 'P', 'P', 'P']);
      expect(a.isComplete, isTrue);
      expect(a.undo().isComplete, isFalse);
    });
  });

  test('JSON round trip', () {
    final a = play(Seat.west, ['1N', 'X', 'XX', 'P', 'P', 'P']);
    final copy = Auction.fromJson(a.toJson());
    expect(copy.dealer, a.dealer);
    expect(copy.calls, a.calls);
  });

  test('random auctions with only legal calls always end', () {
    final random = Random(42);
    for (var n = 0; n < 10000; n++) {
      var a = Auction.start(Seat.values[random.nextInt(4)]);
      var steps = 0;
      while (!a.isComplete) {
        final legal = a.legalCalls().toList();
        // Prefer passes so that auctions end in a normal length.
        final call = random.nextDouble() < 0.6
            ? Call.pass
            : legal[random.nextInt(legal.length)];
        a = a.add(call);
        steps++;
        expect(steps, lessThan(400));
      }
      final outcome = a.outcome;
      if (outcome is ContractReached) {
        final lastBidIndex = a.calls.lastIndexWhere((c) => c.isBid);
        expect(outcome.contract.declarer.side, a.seatOf(lastBidIndex).side);
        expect(outcome.contract.bid, a.lastBid);
      } else {
        expect(a.calls.every((c) => c.isPass), isTrue);
      }
    }
  });
}
