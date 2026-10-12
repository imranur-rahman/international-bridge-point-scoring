import 'package:bridge_scorekeeper/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Seat', () {
    test('rotates clockwise N → E → S → W → N', () {
      expect(Seat.north.next, Seat.east);
      expect(Seat.east.next, Seat.south);
      expect(Seat.south.next, Seat.west);
      expect(Seat.west.next, Seat.north);
      expect(Seat.north.previous, Seat.west);
      expect(Seat.east.after(6), Seat.west);
    });

    test('partner and left-hand opponent', () {
      expect(Seat.south.partner, Seat.north);
      expect(Seat.west.partner, Seat.east);
      expect(Seat.south.leftHandOpponent, Seat.west);
      expect(Seat.west.leftHandOpponent, Seat.north);
    });

    test('sides', () {
      expect(Seat.north.side, Side.northSouth);
      expect(Seat.south.side, Side.northSouth);
      expect(Seat.east.side, Side.eastWest);
      expect(Side.northSouth.opponent, Side.eastWest);
      expect(Side.eastWest.seats, [Seat.east, Seat.west]);
    });
  });

  group('Strain and Bid', () {
    test('strain rank order is ♣ < ♦ < ♥ < ♠ < NT', () {
      expect(Strain.values, [
        Strain.clubs,
        Strain.diamonds,
        Strain.hearts,
        Strain.spades,
        Strain.noTrump,
      ]);
    });

    test('bid comparison', () {
      expect(Bid(2, Strain.spades).isHigherThan(Bid(2, Strain.hearts)), isTrue);
      expect(Bid(3, Strain.clubs).isHigherThan(Bid(2, Strain.noTrump)), isTrue);
      expect(
        Bid(1, Strain.noTrump).isHigherThan(Bid(1, Strain.noTrump)),
        isFalse,
      );
      expect(Bid.all, hasLength(35));
      expect(Bid.all.first, Bid(1, Strain.clubs));
      expect(Bid.all.last, Bid(7, Strain.noTrump));
    });

    test('bid level out of range', () {
      expect(() => Bid(0, Strain.clubs), throwsArgumentError);
      expect(() => Bid(8, Strain.clubs), throwsArgumentError);
    });

    test('text form', () {
      expect(Bid(4, Strain.spades).toString(), '4♠');
      expect(Bid(3, Strain.noTrump).toString(), '3NT');
      expect(Bid(4, Strain.spades).tricksNeeded, 10);
    });
  });

  group('JSON round trip', () {
    test('calls', () {
      final calls = [
        Call.pass,
        Call.double,
        Call.redouble,
        for (final b in Bid.all) Call.bid(b),
      ];
      for (final c in calls) {
        expect(Call.fromJson(c.toJson()), c);
      }
    });

    test('contract', () {
      final c = Contract(
        bid: Bid(6, Strain.noTrump),
        doubling: Doubling.redoubled,
        declarer: Seat.west,
      );
      expect(Contract.fromJson(c.toJson()), c);
      expect(c.toString(), '6NTXX');
    });

    test('vulnerability and enums', () {
      const v = Vulnerability(northSouth: true, eastWest: false);
      expect(Vulnerability.fromJson(v.toJson()), v);
      expect(v.of(Side.northSouth), isTrue);
      for (final s in Seat.values) {
        expect(Seat.fromJson(s.toJson()), s);
      }
      for (final s in Side.values) {
        expect(Side.fromJson(s.toJson()), s);
      }
    });
  });
}
