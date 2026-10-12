import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

LedgerSnapshot replay(
  List<DealResult?> deals, {
  ScoringValues? values,
  ScoringComponents components = allOn,
}) => RubberLedger.replay(deals, values ?? standard, components);

// N-S declares from South, E-W from East.
DealResult nsDeal(String code, {int diff = 0}) =>
    deal(code, diff: diff, declarer: Seat.south);
DealResult ewDeal(String code, {int diff = 0}) =>
    deal(code, diff: diff, declarer: Seat.east);

int itemPts(LedgerDeal d, Side side, ScoreComponent c) => pts(d.score, side, c);

void main() {
  group('Games and part-scores', () {
    test('game from part-scores', () {
      final s = replay([nsDeal('2S'), nsDeal('2C')]);
      expect(s.deals[0].gameWonBy, isNull);
      expect(s.deals[1].gameWonBy, ns);
      expect(s.partScores, {ns: 0, ew: 0});
      expect(s.games[ns], 1);
    });

    test('opponent part-score cancelled', () {
      final s = replay([ewDeal('2N'), nsDeal('4H')]);
      // E-W 70 below, then N-S win the game.
      expect(s.deals[0].score.belowLineFor(ew), 70);
      expect(s.deals[1].gameWonBy, ns);
      expect(s.partScores[ew], 0);
      final next = replay([ewDeal('2N'), nsDeal('4H'), ewDeal('1N')]);
      expect(next.partScores[ew], 40);
      expect(next.deals[2].gameNumber, 2);
    });

    test('game threshold from values', () {
      final values = standard.withValue(ScoringField.gameThreshold, 120);
      expect(replay([nsDeal('4S')], values: values).games[ns], 1);
      expect(replay([nsDeal('3N')], values: values).games[ns], 0);
    });
  });

  group('Game bonus', () {
    final gb = standard
        .withValue(ScoringField.gameBonusNotVulnerable, 300)
        .withValue(ScoringField.gameBonusVulnerable, 500);

    test('game bonus with house rules', () {
      final s = replay([nsDeal('4H')], values: gb);
      expect(s.deals[0].score.belowLineFor(ns), 120);
      expect(itemPts(s.deals[0], ns, ScoreComponent.gameBonus), 300);
    });

    test('game bonus on the game that completes the rubber', () {
      final s = replay([nsDeal('4H'), nsDeal('4H')], values: gb);
      expect(itemPts(s.deals[1], ns, ScoreComponent.gameBonus), 500);
      expect(itemPts(s.deals[1], ns, ScoreComponent.rubberBonus), 700);
    });

    test('standard game bonus does not show', () {
      final s = replay([nsDeal('4H')]);
      expect(
        s.deals[0].score.items.where(
          (i) => i.component == ScoreComponent.gameBonus,
        ),
        isEmpty,
      );
    });
  });

  group('Vulnerability', () {
    test('vulnerable after first game', () {
      final s = replay([nsDeal('4S')]);
      expect(s.deals[0].vulnerability, Vulnerability.none);
      expect(
        s.nextVulnerability,
        const Vulnerability(northSouth: true, eastWest: false),
      );
    });

    test('vulnerability is used by the scorer', () {
      final s = replay([nsDeal('4S'), nsDeal('4SX', diff: -1)]);
      expect(itemPts(s.deals[1], ew, ScoreComponent.undertricks), 200);
    });
  });

  group('Rubber completion and bonus', () {
    test('rubber 2–0', () {
      final s = replay([nsDeal('4S'), nsDeal('3N')]);
      expect(s.deals[1].rubberWonBy, ns);
      expect(itemPts(s.deals[1], ns, ScoreComponent.rubberBonus), 700);
      expect(s.rubbers.first.isComplete, isTrue);
      expect(s.nextRubberNumber, 2);
      expect(s.nextVulnerability, Vulnerability.none);
    });

    test('rubber 2–1', () {
      final s = replay([nsDeal('4S'), ewDeal('4H'), nsDeal('5C')]);
      expect(itemPts(s.deals[2], ns, ScoreComponent.rubberBonus), 500);
    });

    test('full rubber with a clean slate after it', () {
      final s = replay([
        nsDeal('4S'),
        ewDeal('4H'),
        nsDeal('4S'),
        ewDeal('1C'),
      ]);
      expect(s.deals[2].vulnerability, bothV);
      expect(itemPts(s.deals[2], ns, ScoreComponent.rubberBonus), 500);
      final d4 = s.deals[3];
      expect(d4.rubberNumber, 2);
      expect(d4.gameNumber, 1);
      expect(d4.vulnerability, Vulnerability.none);
      expect(s.games, {ns: 0, ew: 0});
      expect(s.partScores, {ns: 0, ew: 20});
    });

    test('House rules rubber bonus', () {
      final a = replay([nsDeal('4S'), nsDeal('4S')], values: house);
      expect(itemPts(a.deals[1], ns, ScoreComponent.rubberBonus), 250);
      final b = replay([
        nsDeal('4S'),
        ewDeal('4S'),
        nsDeal('4S'),
      ], values: house);
      expect(itemPts(b.deals[2], ns, ScoreComponent.rubberBonus), 250);
    });
  });

  group('Unfinished rubber bonus', () {
    test('one game and a part-score', () {
      final s = replay([nsDeal('4S'), ewDeal('2C')]);
      expect(s.unfinishedRubberBonus(), [
        const ScoreItem(ns, ScoreComponent.unfinishedRubber, 300),
        const ScoreItem(ew, ScoreComponent.unfinishedRubber, 100),
      ]);
    });

    test('one game each', () {
      final s = replay([nsDeal('4S'), ewDeal('4S')]);
      expect(s.unfinishedRubberBonus(), isEmpty);
    });

    test('House rules unfinished rubber', () {
      final s = replay([nsDeal('4S'), ewDeal('2C')], values: house);
      expect(s.unfinishedRubberBonus(), [
        const ScoreItem(ns, ScoreComponent.unfinishedRubber, 125),
      ]);
    });

    test('unfinished rubber bonus off', () {
      final s = replay([
        nsDeal('4S'),
        ewDeal('2C'),
      ], components: const ScoringComponents(unfinishedRubberBonus: false));
      expect(s.unfinishedRubberBonus(), isEmpty);
    });

    test('no bonus right after a completed rubber', () {
      final s = replay([nsDeal('4S'), nsDeal('4S')]);
      expect(s.unfinishedRubberBonus(), isEmpty);
    });
  });

  group('Session total', () {
    test('total over two rubbers', () {
      final s = replay([
        nsDeal('4S'),
        nsDeal('4S'),
        ewDeal('2H'),
        nsDeal('3N', diff: 1),
      ]);
      expect(s.rubbers, hasLength(2));
      final sumOfRubbers = s.rubbers.fold(0, (a, r) => a + r.totals[ns]!);
      expect(s.totalFor(ns), sumOfRubbers);
      // 120 + 120 + 700 + 100 + 30.
      expect(s.totalFor(ns), 1070);
      expect(s.totalFor(ew), 60);
    });

    test('final total adds the unfinished rubber bonus', () {
      final s = replay([nsDeal('4S')]);
      expect(s.totalFor(ns), 120);
      expect(s.finalTotalFor(ns), 420);
    });

    test('passed-out deals score nothing and still count', () {
      final s = replay([null, nsDeal('4S'), null]);
      expect(s.deals, hasLength(3));
      expect(s.deals[0].isPassedOut, isTrue);
      expect(s.totalFor(ns), 120);
      expect(s.deals[2].vulnerability.northSouth, isTrue);
    });
  });

  group('Deterministic recalculation', () {
    test('same list gives the same snapshot', () {
      final deals = [nsDeal('4S'), ewDeal('3NX', diff: -2), null, nsDeal('6H')];
      final a = replay(deals);
      final b = replay(List.of(deals));
      for (var i = 0; i < deals.length; i++) {
        expect(a.deals[i].score.items, b.deals[i].score.items);
        expect(a.deals[i].vulnerability, b.deals[i].vulnerability);
      }
      expect(a.totalFor(ns), b.totalFor(ns));
    });

    test('recalculation after edit changes later vulnerability', () {
      final original = [nsDeal('4S'), ewDeal('1C'), nsDeal('3NX', diff: -1)];
      final a = replay(original);
      expect(a.deals[2].vulnerability.northSouth, isTrue);
      final edited = [nsDeal('4S', diff: -1), ...original.skip(1)];
      final b = replay(edited);
      expect(b.deals[2].vulnerability.northSouth, isFalse);
      expect(itemPts(b.deals[2], ew, ScoreComponent.undertricks), 100);
    });
  });

  test('every field changes the score of a matching deal list', () {
    // For each field: a deal list where the field matters.
    final cases = <ScoringField, List<DealResult?>>{
      ScoringField.minorTrick: [nsDeal('2C')],
      ScoringField.majorTrick: [nsDeal('2H')],
      ScoringField.noTrumpFirstTrick: [nsDeal('1N')],
      ScoringField.noTrumpLaterTrick: [nsDeal('2N')],
      ScoringField.doubleMultiplier: [nsDeal('1HX')],
      ScoringField.redoubleMultiplier: [nsDeal('1HXX')],
      ScoringField.overtrickDoubledNotVulnerable: [nsDeal('1HX', diff: 1)],
      ScoringField.overtrickDoubledVulnerable: [
        nsDeal('4S'),
        nsDeal('1HX', diff: 1),
      ],
      ScoringField.insultDoubled: [nsDeal('1HX')],
      ScoringField.insultRedoubled: [nsDeal('1HXX')],
      ScoringField.gameThreshold: [nsDeal('3N')],
      ScoringField.gameBonusNotVulnerable: [nsDeal('4S')],
      ScoringField.gameBonusVulnerable: [nsDeal('4S'), nsDeal('4S')],
      ScoringField.smallSlamNotVulnerable: [nsDeal('6S')],
      ScoringField.smallSlamVulnerable: [nsDeal('4S'), nsDeal('6S')],
      ScoringField.grandSlamNotVulnerable: [nsDeal('7S')],
      ScoringField.grandSlamVulnerable: [nsDeal('4S'), nsDeal('7S')],
      ScoringField.undertrickUndoubledNotVulnerable: [nsDeal('4S', diff: -1)],
      ScoringField.undertrickUndoubledVulnerable: [
        nsDeal('4S'),
        nsDeal('4S', diff: -1),
      ],
      ScoringField.undertrickDoubledNotVulnerableFirst: [
        nsDeal('4SX', diff: -1),
      ],
      ScoringField.undertrickDoubledNotVulnerableSecondThird: [
        nsDeal('4SX', diff: -2),
      ],
      ScoringField.undertrickDoubledNotVulnerableFourthOn: [
        nsDeal('4SX', diff: -4),
      ],
      ScoringField.undertrickDoubledVulnerableFirst: [
        nsDeal('4S'),
        nsDeal('4SX', diff: -1),
      ],
      ScoringField.undertrickDoubledVulnerableSecondThird: [
        nsDeal('4S'),
        nsDeal('4SX', diff: -2),
      ],
      ScoringField.undertrickDoubledVulnerableFourthOn: [
        nsDeal('4S'),
        nsDeal('4SX', diff: -4),
      ],
      ScoringField.honorsFourInOneHand: [
        deal('2S', honors: const Honors(HonorsHolding.fourInOneHand, ns)),
      ],
      ScoringField.honorsFiveInOneHand: [
        deal('2S', honors: const Honors(HonorsHolding.fiveInOneHand, ns)),
      ],
      ScoringField.honorsEachOther: [
        deal('2S', honors: const Honors(HonorsHolding.fourPlusOne, ns)),
      ],
      ScoringField.acesFourInOneHand: [
        deal('1N', honors: const Honors(HonorsHolding.fourAcesInOneHand, ew)),
      ],
      ScoringField.acesEachOther: [
        deal('1N', honors: const Honors(HonorsHolding.threeAces, ew)),
      ],
      ScoringField.rubberTwoNil: [nsDeal('4S'), nsDeal('4S')],
      ScoringField.rubberTwoOne: [nsDeal('4S'), ewDeal('4S'), nsDeal('4S')],
      ScoringField.unfinishedOneGame: [nsDeal('4S')],
      ScoringField.unfinishedPartScore: [nsDeal('2S')],
    };
    expect(cases.keys.toSet(), ScoringField.values.toSet());

    int finalSum(ScoringValues v, List<DealResult?> deals) {
      final s = replay(deals, values: v);
      return s.finalTotalFor(ns) * 100000 + s.finalTotalFor(ew);
    }

    for (final e in cases.entries) {
      final changed = standard.withValue(e.key, standard[e.key] + 7);
      expect(
        finalSum(changed, e.value),
        isNot(finalSum(standard, e.value)),
        reason: '${e.key} has no effect',
      );
    }
  });
}
