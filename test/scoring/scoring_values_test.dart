import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The "Scoring values table" requirement of the rubber-scoring spec:
  // field: [standard default, House rules default].
  const table = <ScoringField, List<int>>{
    ScoringField.minorTrick: [20, 20],
    ScoringField.majorTrick: [30, 30],
    ScoringField.noTrumpFirstTrick: [40, 40],
    ScoringField.noTrumpLaterTrick: [30, 30],
    ScoringField.doubleMultiplier: [2, 2],
    ScoringField.redoubleMultiplier: [4, 4],
    ScoringField.gameThreshold: [100, 100],
    ScoringField.overtrickDoubledNotVulnerable: [100, 100],
    ScoringField.overtrickDoubledVulnerable: [200, 200],
    ScoringField.insultDoubled: [50, 50],
    ScoringField.insultRedoubled: [100, 100],
    ScoringField.smallSlamNotVulnerable: [500, 500],
    ScoringField.smallSlamVulnerable: [750, 750],
    ScoringField.grandSlamNotVulnerable: [1000, 1000],
    ScoringField.grandSlamVulnerable: [1500, 1500],
    ScoringField.undertrickUndoubledNotVulnerable: [50, 50],
    ScoringField.undertrickUndoubledVulnerable: [100, 100],
    ScoringField.undertrickDoubledNotVulnerableFirst: [100, 100],
    ScoringField.undertrickDoubledNotVulnerableSecondThird: [200, 200],
    ScoringField.undertrickDoubledNotVulnerableFourthOn: [300, 300],
    ScoringField.undertrickDoubledVulnerableFirst: [200, 200],
    ScoringField.undertrickDoubledVulnerableSecondThird: [300, 300],
    ScoringField.undertrickDoubledVulnerableFourthOn: [300, 300],
    ScoringField.honorsFourInOneHand: [100, 80],
    ScoringField.honorsFiveInOneHand: [150, 100],
    ScoringField.honorsEachOther: [0, 10],
    ScoringField.acesFourInOneHand: [150, 80],
    ScoringField.acesEachOther: [0, 10],
    ScoringField.gameBonusNotVulnerable: [0, 0],
    ScoringField.gameBonusVulnerable: [0, 0],
    ScoringField.rubberTwoNil: [700, 250],
    ScoringField.rubberTwoOne: [500, 250],
    ScoringField.unfinishedOneGame: [300, 125],
    ScoringField.unfinishedPartScore: [100, 0],
  };

  test('there are 34 fields', () {
    expect(ScoringField.values, hasLength(34));
    expect(table, hasLength(34));
  });

  test('defaults match the spec table exactly', () {
    final s = ScoringValues.standard();
    final h = ScoringValues.houseDefaults();
    for (final entry in table.entries) {
      expect(s[entry.key], entry.value[0], reason: 'standard ${entry.key}');
      expect(h[entry.key], entry.value[1], reason: 'house ${entry.key}');
    }
  });

  test('House rules defaults differ from Standard in 9 values', () {
    final diff = ScoringValues.houseDefaults().differsFrom(
      ScoringValues.standard(),
    );
    expect(diff, hasLength(9));
    expect(diff.map((f) => f.group).toSet(), {
      ScoringGroup.honors,
      ScoringGroup.rubber,
    });
  });

  test('values out of range give field errors', () {
    final s = ScoringValues.standard();
    expect(s.validate(), isEmpty);
    expect(
      s.withValue(ScoringField.smallSlamNotVulnerable, -50).validate().keys,
      [ScoringField.smallSlamNotVulnerable],
    );
    expect(s.withValue(ScoringField.gameThreshold, 0).validate().keys, [
      ScoringField.gameThreshold,
    ]);
    expect(
      s.withValue(ScoringField.minorTrick, 100001).validate(),
      hasLength(1),
    );
    expect(s.withValue(ScoringField.minorTrick, 0).validate(), isEmpty);
  });

  test('JSON round trip', () {
    final v = ScoringValues.houseDefaults().withValue(
      ScoringField.gameThreshold,
      120,
    );
    expect(ScoringValues.fromJson(v.toJson()), v);
  });

  test('every group has fields, in screen order', () {
    expect(ScoringGroup.values.map((g) => g.label), [
      'Trick values',
      'Double and redouble',
      'Game',
      'Slams',
      'Undertricks (penalties)',
      'Honors',
      'Rubber',
    ]);
    for (final g in ScoringGroup.values) {
      expect(ScoringField.inGroup(g), isNotEmpty);
    }
  });
}
