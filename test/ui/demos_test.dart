import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everything that a demo shows at its last step.
String outcome(ScoringDemo demo, ScoringValues values) {
  final n = demo.steps.length;
  final ledger = demo.replay(n, values);
  return [
    for (final d in ledger.deals) ...[
      d.score.items.join(','),
      'game:${d.gameWonBy}',
      'rubber:${d.rubberWonBy}',
    ],
    demo.sessionEndItems(n, values).join(','),
  ].join('|');
}

void main() {
  final standard = ScoringValues.standard();

  test('each field has a demo with 1 to 3 steps', () {
    expect(scoringDemos.keys.toSet(), ScoringField.values.toSet());
    for (final e in scoringDemos.entries) {
      expect(e.value.field, e.key);
      expect(e.value.steps.length, inInclusiveRange(1, 3), reason: '${e.key}');
      for (final s in e.value.steps) {
        expect(s.text, isNotEmpty);
      }
    }
  });

  test('each demo shows a change of its value', () {
    for (final demo in scoringDemos.values) {
      final changed = standard.withValue(demo.field, standard[demo.field] + 7);
      expect(
        outcome(demo, changed),
        isNot(outcome(demo, standard)),
        reason: '${demo.field} has no effect in its demo',
      );
    }
  });

  test('each highlighted component has points at the last step', () {
    for (final demo in scoringDemos.values) {
      // Fields with a standard value of 0 show 0 points with Standard.
      if (standard[demo.field] == 0) continue;
      final n = demo.steps.length;
      final items = [
        ...demo.replay(n, standard).deals.last.score.items,
        ...demo.sessionEndItems(n, standard),
      ];
      expect(
        items.any((i) => i.component == demo.highlight && i.points > 0),
        isTrue,
        reason: '${demo.field}',
      );
    }
  });

  test('rubber 2–1 demo with standard and changed values', () {
    final demo = scoringDemos[ScoringField.rubberTwoOne]!;
    final last = demo.replay(3, standard).deals.last;
    expect(last.rubberWonBy, Side.northSouth);
    expect(last.score.componentTotal(ScoreComponent.rubberBonus), 500);
    final house = standard.withValue(ScoringField.rubberTwoOne, 400);
    expect(
      demo
          .replay(3, house)
          .deals
          .last
          .score
          .componentTotal(ScoreComponent.rubberBonus),
      400,
    );
  });

  test('unfinished rubber demo ends the session', () {
    final demo = scoringDemos[ScoringField.unfinishedOneGame]!;
    final items = demo.sessionEndItems(1, standard);
    expect(items.single.side, Side.northSouth);
    expect(items.single.points, 300);
  });
}
