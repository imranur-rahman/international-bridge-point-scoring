import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Contract points below the line', () {
    test('minor suit part-score', () {
      expect(pts(scoreOf(deal('3D')), ns, ScoreComponent.contractPoints), 60);
    });
    test('no trump game', () {
      expect(pts(scoreOf(deal('3N')), ns, ScoreComponent.contractPoints), 100);
    });
    test('doubled contract', () {
      expect(pts(scoreOf(deal('2HX')), ns, ScoreComponent.contractPoints), 120);
    });
    test('redoubled contract', () {
      expect(
        pts(scoreOf(deal('1NXX')), ns, ScoreComponent.contractPoints),
        160,
      );
    });
    test('1♣ redoubled and 7NT', () {
      expect(pts(scoreOf(deal('1CXX')), ns, ScoreComponent.contractPoints), 80);
      expect(pts(scoreOf(deal('7N')), ns, ScoreComponent.contractPoints), 220);
    });
    test('changed value is used', () {
      final values = standard.withValue(ScoringField.majorTrick, 35);
      final s = scoreOf(deal('2S'), values: values);
      expect(pts(s, ns, ScoreComponent.contractPoints), 70);
    });
  });

  group('Overtricks above the line', () {
    test('undoubled overtricks', () {
      final s = scoreOf(deal('2S', diff: 2));
      expect(s.belowLineFor(ns), 60);
      expect(pts(s, ns, ScoreComponent.overtricks), 60);
    });
    test('no trump overtricks use the later trick value', () {
      final s = scoreOf(deal('1N', diff: 2));
      expect(pts(s, ns, ScoreComponent.overtricks), 60);
    });
    test('doubled overtrick, vulnerable', () {
      final s = scoreOf(deal('3CX', diff: 1), v: bothV);
      expect(s.belowLineFor(ns), 120);
      expect(pts(s, ns, ScoreComponent.overtricks), 200);
      expect(pts(s, ns, ScoreComponent.insultBonus), 50);
    });
    test('redoubled value follows the doubled value', () {
      final values = standard.withValue(
        ScoringField.overtrickDoubledNotVulnerable,
        150,
      );
      final s = scoreOf(deal('1SXX', diff: 1), values: values);
      expect(pts(s, ns, ScoreComponent.overtricks), 300);
    });
    test('redoubled overtricks with standard values', () {
      expect(
        pts(scoreOf(deal('1SXX', diff: 1)), ns, ScoreComponent.overtricks),
        200,
      );
      expect(
        pts(
          scoreOf(deal('1SXX', diff: 1), v: bothV),
          ns,
          ScoreComponent.overtricks,
        ),
        400,
      );
    });
  });

  group('Insult bonus', () {
    test('redoubled contract fulfilled', () {
      final s = scoreOf(deal('2DXX'));
      expect(s.belowLineFor(ns), 160);
      expect(pts(s, ns, ScoreComponent.insultBonus), 100);
    });
    test('no insult bonus when the contract fails', () {
      final s = scoreOf(deal('2DX', diff: -1));
      expect(pts(s, ns, ScoreComponent.insultBonus), 0);
    });
  });

  group('Slam bonuses', () {
    test('small slam not vulnerable', () {
      final s = scoreOf(deal('6H'));
      expect(s.belowLineFor(ns), 180);
      expect(pts(s, ns, ScoreComponent.slamBonus), 500);
    });
    test('grand slam vulnerable', () {
      final s = scoreOf(deal('7N'), v: bothV);
      expect(s.belowLineFor(ns), 220);
      expect(pts(s, ns, ScoreComponent.slamBonus), 1500);
    });
    test('small slam vulnerable and grand slam not vulnerable', () {
      expect(
        pts(scoreOf(deal('6C'), v: bothV), ns, ScoreComponent.slamBonus),
        750,
      );
      expect(pts(scoreOf(deal('7C')), ns, ScoreComponent.slamBonus), 1000);
    });
    test('no slam bonus when the slam fails', () {
      final s = scoreOf(deal('6H', diff: -1));
      expect(pts(s, ns, ScoreComponent.slamBonus), 0);
    });
  });

  group('Undertrick penalties', () {
    test('undoubled, not vulnerable', () {
      final s = scoreOf(deal('4S', diff: -2));
      expect(pts(s, ew, ScoreComponent.undertricks), 100);
      expect(s.totalFor(ns), 0);
    });
    test('doubled, not vulnerable, down 4', () {
      final s = scoreOf(deal('4SX', diff: -4));
      expect(pts(s, ew, ScoreComponent.undertricks), 800);
    });
    test('doubled, vulnerable, down 3', () {
      final s = scoreOf(deal('4SX', diff: -3), v: bothV);
      expect(pts(s, ew, ScoreComponent.undertricks), 800);
    });
    test('redoubled, vulnerable, down 1', () {
      final s = scoreOf(deal('4SXX', diff: -1), v: bothV);
      expect(pts(s, ew, ScoreComponent.undertricks), 400);
    });
    test('equal undertricks in House rules', () {
      final values = standard
          .withValue(
            ScoringField.undertrickDoubledNotVulnerableSecondThird,
            100,
          )
          .withValue(ScoringField.undertrickDoubledNotVulnerableFourthOn, 100);
      expect(
        pts(
          scoreOf(deal('4SX', diff: -3), values: values),
          ew,
          ScoreComponent.undertricks,
        ),
        300,
      );
      expect(
        pts(
          scoreOf(deal('4SXX', diff: -3), values: values),
          ew,
          ScoreComponent.undertricks,
        ),
        600,
      );
    });

    test('table of 1 to 13 undertricks', () {
      // Standard values of each undertrick by position.
      int each(int position, Doubling d, bool v) {
        final int value;
        if (d == Doubling.none) {
          value = v ? 100 : 50;
        } else if (position == 1) {
          value = v ? 200 : 100;
        } else if (position <= 3) {
          value = v ? 300 : 200;
        } else {
          value = 300;
        }
        return d == Doubling.redoubled ? 2 * value : value;
      }

      for (final d in Doubling.values) {
        for (final v in [false, true]) {
          for (var down = 1; down <= 13; down++) {
            var expected = 0;
            for (var p = 1; p <= down; p++) {
              expected += each(p, d, v);
            }
            final r = DealResult(
              contract: Contract(
                bid: Bid(7, Strain.noTrump),
                doubling: d,
                declarer: Seat.north,
              ),
              tricksTaken: 13 - down,
            );
            final s = DealScorer.score(r, v ? bothV : nv, standard, allOn);
            expect(
              pts(s, ew, ScoreComponent.undertricks),
              expected,
              reason: '$d vulnerable=$v down $down',
            );
          }
        }
      }
    });

    test('known totals', () {
      // Down 1–4: doubled NV 100, 300, 500, 800; doubled V 200, 500, 800,
      // 1100; redoubled NV 200, 600, 1000, 1600; redoubled V 400, 1000,
      // 1600, 2200.
      const expected = {
        'X-nv': [100, 300, 500, 800],
        'X-v': [200, 500, 800, 1100],
        'XX-nv': [200, 600, 1000, 1600],
        'XX-v': [400, 1000, 1600, 2200],
      };
      for (final e in expected.entries) {
        final code = e.key.startsWith('XX') ? '4SXX' : '4SX';
        final v = e.key.endsWith('-v') ? bothV : nv;
        for (var down = 1; down <= 4; down++) {
          expect(
            pts(
              scoreOf(deal(code, diff: -down), v: v),
              ew,
              ScoreComponent.undertricks,
            ),
            e.value[down - 1],
            reason: '${e.key} down $down',
          );
        }
      }
    });
  });

  group('Honors', () {
    test('honors with a failed contract', () {
      final s = scoreOf(
        deal(
          '4S',
          diff: -1,
          honors: const Honors(HonorsHolding.fiveInOneHand, Side.northSouth),
        ),
      );
      expect(pts(s, ns, ScoreComponent.honors), 150);
      expect(pts(s, ew, ScoreComponent.undertricks), 50);
    });

    test('aces at no trump', () {
      final s = scoreOf(
        deal(
          '3N',
          honors: const Honors(HonorsHolding.fourAcesInOneHand, Side.eastWest),
        ),
      );
      expect(pts(s, ew, ScoreComponent.honors), 150);
    });

    test('standard, honors split', () {
      final s = scoreOf(
        deal(
          '4S',
          honors: const Honors(HonorsHolding.fourSplit, Side.northSouth),
        ),
      );
      expect(pts(s, ns, ScoreComponent.honors), 0);
      expect(pts(s, ew, ScoreComponent.honors), 0);
    });

    test('standard values for each holding', () {
      const expected = {
        HonorsHolding.threeHonors: 0,
        HonorsHolding.fourSplit: 0,
        HonorsHolding.fourInOneHand: 100,
        HonorsHolding.fiveSplit: 0,
        HonorsHolding.fourPlusOne: 100,
        HonorsHolding.fiveInOneHand: 150,
        HonorsHolding.noneTwoTwo: 0,
        HonorsHolding.threeAces: 0,
        HonorsHolding.fourAcesSplit: 0,
        HonorsHolding.fourAcesInOneHand: 150,
      };
      for (final e in expected.entries) {
        expect(e.key.points(standard), e.value, reason: '${e.key}');
      }
    });

    test('House rules, honors patterns in a suit contract', () {
      const expected = {
        HonorsHolding.threeHonors: 30,
        HonorsHolding.fourSplit: 40,
        HonorsHolding.fourInOneHand: 80,
        HonorsHolding.fiveSplit: 50,
        HonorsHolding.fourPlusOne: 90,
        HonorsHolding.fiveInOneHand: 100,
      };
      for (final e in expected.entries) {
        final s = scoreOf(
          deal('4H', honors: Honors(e.key, Side.eastWest)),
          values: house,
        );
        expect(pts(s, ew, ScoreComponent.honors), e.value, reason: '${e.key}');
      }
    });

    test('House rules, aces at no trump', () {
      expect(HonorsHolding.threeAces.points(house), 30);
      expect(HonorsHolding.fourAcesSplit.points(house), 40);
      expect(HonorsHolding.fourAcesInOneHand.points(house), 80);
      final s = scoreOf(deal('3N', honors: Honors.none), values: house);
      expect(pts(s, ns, ScoreComponent.honors), 0);
      expect(pts(s, ew, ScoreComponent.honors), 0);
    });

    test('House rules, minority side scores nothing', () {
      final s = scoreOf(
        deal(
          '2S',
          honors: const Honors(HonorsHolding.threeHonors, Side.northSouth),
        ),
        values: house,
      );
      expect(pts(s, ns, ScoreComponent.honors), 30);
      expect(pts(s, ew, ScoreComponent.honors), 0);
    });

    test('honors switched off', () {
      final s = scoreOf(
        deal(
          '4S',
          honors: const Honors(HonorsHolding.fiveInOneHand, Side.northSouth),
        ),
        components: const ScoringComponents(honors: false),
      );
      expect(pts(s, ns, ScoreComponent.honors), 0);
    });

    test('honors holdings by strain', () {
      expect(HonorsHolding.forStrain(Strain.noTrump), [
        HonorsHolding.noneTwoTwo,
        HonorsHolding.threeAces,
        HonorsHolding.fourAcesSplit,
        HonorsHolding.fourAcesInOneHand,
      ]);
      expect(HonorsHolding.forStrain(Strain.hearts), hasLength(6));
    });
  });

  group('Result words', () {
    test('fulfilled, overtricks, and undertricks', () {
      expect(deal('4S').fullResult, 'Contract fulfilled');
      expect(
        deal('2H', diff: 2).fullResult,
        'Contract fulfilled with 2 overtricks',
      );
      expect(deal('3N', diff: -2).fullResult, 'Down 2 (2 undertricks)');
      expect(deal('3N', diff: -2).tricksTaken, 7);
      expect(deal('4S', diff: 1).shortResult, '+1');
      expect(deal('4S', diff: -2).shortResult, '−2');
      expect(deal('4S').shortResult, 'Made');
    });
  });

  test('JSON round trip of a result', () {
    final r = deal(
      '4HX',
      diff: -1,
      declarer: Seat.east,
      honors: const Honors(HonorsHolding.fourPlusOne, Side.eastWest),
    );
    expect(DealResult.fromJson(r.toJson()), r);
    final n = deal('3N', honors: Honors.none);
    expect(DealResult.fromJson(n.toJson()), n);
  });
}
