import 'dart:convert';

import 'package:bridge_scorekeeper/core/core.dart';
import 'package:bridge_scorekeeper/scoring/scoring.dart';
import 'package:bridge_scorekeeper/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Matcher throwsInvalid = throwsA(isA<InvalidCommandException>());

void main() {
  group('Player names by seat', () {
    test('valid names', () {
      final raw = {
        Seat.north: 'Alice',
        Seat.east: 'Bob',
        Seat.south: 'Carol',
        Seat.west: 'Dave',
      };
      expect(Players.validate(raw), isEmpty);
      expect(Players(raw).nameOf(Seat.west), 'Dave');
    });

    test('empty name', () {
      final errors = Players.validate({
        Seat.north: 'Alice',
        Seat.east: 'Bob',
        Seat.south: '   ',
        Seat.west: 'Dave',
      });
      expect(errors.keys, [Seat.south]);
    });

    test('duplicate name', () {
      final errors = Players.validate({
        Seat.north: 'Alice',
        Seat.east: 'Bob',
        Seat.south: 'Carol',
        Seat.west: 'alice ',
      });
      expect(errors[Seat.west], 'Each player needs a different name');
    });

    test('names are trimmed', () {
      final p = Players({
        Seat.north: ' Alice ',
        Seat.east: 'Bob',
        Seat.south: 'Carol',
        Seat.west: 'Dave',
      });
      expect(p.nameOf(Seat.north), 'Alice');
    });
  });

  test('partnership names', () {
    expect(players.partnershipName(Side.northSouth), 'Alice & Carol');
    expect(players.partnershipName(Side.eastWest), 'Bob & Dave');
  });

  group('End rule configuration', () {
    test('ranges', () {
      expect(const DealCountRule(8).validate(), isNull);
      expect(const DealCountRule(0).validate(), isNotNull);
      expect(const DealCountRule(201).validate(), isNotNull);
      expect(const TargetScoreRule(3000).validate(), isNull);
      expect(const TargetScoreRule(99).validate(), isNotNull);
      expect(const TargetScoreRule(100001).validate(), isNotNull);
    });

    test('JSON', () {
      for (final r in const [DealCountRule(8), TargetScoreRule(3000)]) {
        expect(EndRule.fromJson(r.toJson()), r);
      }
    });
  });

  group('Deal stages', () {
    test('normal deal without bidding step', () {
      var s = newSession();
      final stages = <DealStage>[s.draft!.stage];
      for (final c in <SessionCommand>[
        const AdvanceFromStart(),
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(10),
        const ScoreDeal(),
      ]) {
        s = SessionController.apply(s, c, now: t0);
        if (stages.last != s.draft!.stage) stages.add(s.draft!.stage);
      }
      expect(stages, [
        DealStage.start,
        DealStage.contract,
        DealStage.play,
        DealStage.result,
        DealStage.scored,
      ]);
      expect(s.records, hasLength(1));
    });

    test('normal deal with bidding step', () {
      var s = newSession(settings(bidding: true, firstDealer: Seat.east));
      s = run(s, [const AdvanceFromStart()]);
      expect(s.draft!.stage, DealStage.auction);
      for (final code in ['P', '1N', 'P', '3N', 'X', 'P', 'P', 'P']) {
        s = run(s, [RecordCall(Call.fromJson(code))]);
      }
      expect(s.draft!.stage, DealStage.contract);
      expect(s.draft!.contract.toContract().toString(), '3NTX');
      expect(s.draft!.contract.declarer, Seat.south);
      expect(
        () => run(s, [SetContract(contract('4S', Seat.north))]),
        throwsInvalid,
      );
      s = run(s, [const Back()]);
      expect(s.draft!.stage, DealStage.auction);
      s = run(s, [const UndoCall()]);
      expect(s.draft!.auction!.isComplete, isFalse);
    });

    test('move back before scoring keeps data', () {
      var s = run(newSession(), [
        const AdvanceFromStart(),
        SetContract(contract('4S', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(9),
        const Back(),
      ]);
      expect(s.draft!.stage, DealStage.play);
      expect(s.draft!.tricksTaken, 9);
      s = run(s, [const FinishPlay()]);
      expect(s.draft!.tricksTaken, 9);
    });

    test('incomplete contract cannot move to play', () {
      final s = run(newSession(), [
        const AdvanceFromStart(),
        const SetContract(ContractInput(level: 4, strain: Strain.spades)),
      ]);
      expect(() => run(s, [const ConfirmContract()]), throwsInvalid);
    });

    test('command at the wrong stage is rejected', () {
      final s = newSession();
      expect(() => run(s, [const FinishPlay()]), throwsInvalid);
      expect(() => run(s, [const Back()]), throwsInvalid);
      expect(() => run(s, [const RecordCall(Call.pass)]), throwsInvalid);
    });

    test('honors are needed when honors are on', () {
      var s = newSession(settings(components: const ScoringComponents()));
      s = run(s, [
        const AdvanceFromStart(),
        SetContract(contract('4H', Seat.south)),
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(10),
      ]);
      expect(() => run(s, [const ScoreDeal()]), throwsInvalid);
      expect(
        () => run(s, [
          const SetHonors(Honors(HonorsHolding.threeAces, Side.eastWest)),
        ]),
        throwsInvalid,
      );
      s = run(s, [
        const SetHonors(Honors(HonorsHolding.fourPlusOne, Side.eastWest)),
        const ScoreDeal(),
      ]);
      expect(s.records.single.result!.honors!.side, Side.eastWest);
    });
  });

  group('Passed-out deal', () {
    test('all four players pass', () {
      var s = newSession(settings(bidding: true));
      s = run(s, [
        const AdvanceFromStart(),
        for (var i = 0; i < 4; i++) const RecordCall(Call.pass),
      ]);
      expect(s.records.single.isPassedOut, isTrue);
      expect(s.draft!.stage, DealStage.start);
      expect(s.draft!.dealer, Seat.east);
      expect(s.ledger.totalFor(Side.northSouth), 0);
    });

    test('passed out at the contract stage', () {
      final s = passOut(newSession());
      expect(s.records.single.isPassedOut, isTrue);
      expect(s.currentDealNumber, 2);
    });
  });

  test('dealer rotation', () {
    var s = newSession(settings(firstDealer: Seat.west));
    s = playDeal(s, '1C', Seat.west);
    s = passOut(s);
    // Deal 3 is dealt by East.
    expect(s.draft!.dealer, Seat.east);
    s = playDeal(s, '2C', Seat.east);
    expect(s.draft!.dealer, Seat.south);
  });

  group('Play roles', () {
    test('roles for a South declarer', () {
      final r = PlayRoles.of(Seat.south);
      expect(r.dummy, Seat.north);
      expect(r.openingLeader, Seat.west);
    });
    test('roles for a West declarer', () {
      final r = PlayRoles.of(Seat.west);
      expect(r.dummy, Seat.east);
      expect(r.openingLeader, Seat.north);
    });
  });

  group('Result options', () {
    test('buttons for a game contract', () {
      final options = ResultOption.forLevel(4);
      expect(options.first.label, '−10');
      expect(options.map((o) => o.label), contains('Made'));
      expect(options.last.label, '+3');
      expect(options, hasLength(14));
      expect(options.firstWhere((o) => o.label == 'Made').tricksTaken, 10);
    });
    test('no overtrick at the grand slam', () {
      final options = ResultOption.forLevel(7);
      expect(options.last.label, 'Made');
      expect(options.where((o) => o.label.startsWith('+')), isEmpty);
    });
  });

  group('Session end', () {
    test('end by number of deals', () {
      var s = newSession(settings(endRule: const DealCountRule(4)));
      for (var i = 0; i < 3; i++) {
        s = playDeal(s, '1C', Seat.north);
      }
      expect(s.isEnded, isFalse);
      s = playDeal(s, '1C', Seat.north);
      expect(s.isEnded, isTrue);
      expect(s.endReason, EndReason.endRule);
      expect(s.draft!.stage, DealStage.scored);
      expect(() => run(s, [const NextDeal()]), throwsInvalid);
    });

    test('end by target score', () {
      var s = newSession(settings(endRule: const TargetScoreRule(1000)));
      s = playDeal(s, '4S', Seat.east);
      s = playDeal(s, '4S', Seat.east);
      // 120 + 120 + 700 = 940.
      expect(s.isEnded, isFalse);
      s = playDeal(s, '2S', Seat.east, diff: 2);
      // 940 + 60 + 60 = 1060.
      expect(s.isEnded, isTrue);
      expect(SessionSummary.of(s).winner, Side.eastWest);
    });

    test('early end between deals adds the unfinished rubber bonus', () {
      var s = playDeal(newSession(), '4S', Seat.north);
      expect(
        () => run(s, [const AdvanceFromStart(), const EndSession()]),
        throwsInvalid,
      );
      s = run(s, [const EndSession()]);
      expect(s.isEnded, isTrue);
      expect(s.endReason, EndReason.early);
      final summary = SessionSummary.of(s);
      expect(summary.finalTotals[Side.northSouth], 420);
      expect(summary.unfinishedBonus.single.points, 300);
    });

    test('undo of the last deal reopens the session', () {
      var s = newSession(settings(endRule: const DealCountRule(2)));
      s = playDeal(s, '1C', Seat.north);
      s = playDeal(s, '1C', Seat.east);
      expect(s.isEnded, isTrue);
      s = run(s, [const UndoLastDeal()]);
      expect(s.isEnded, isFalse);
      expect(s.currentDealNumber, 2);
      expect(s.draft!.dealer, Seat.east);
    });

    test('edit reopens a session that ended by the target', () {
      var s = newSession(settings(endRule: const TargetScoreRule(300)));
      s = playDeal(s, '4S', Seat.north);
      s = playDeal(s, '4S', Seat.north);
      expect(s.isEnded, isTrue);
      final r = s.records[1].result!;
      s = run(s, [EditDeal(1, r.copyWith(tricksTaken: 9))]);
      expect(s.isEnded, isFalse);
      expect(s.draft!.stage, DealStage.start);
      expect(s.currentDealNumber, 3);
    });
  });

  group('Undo last deal', () {
    test('undo', () {
      var s = newSession();
      for (var i = 0; i < 5; i++) {
        s = playDeal(s, '1C', Seat.north);
      }
      final dealerOf5 = s.records[4].dealer;
      s = run(s, [const UndoLastDeal()]);
      expect(s.records, hasLength(4));
      expect(s.currentDealNumber, 5);
      expect(s.draft!.dealer, dealerOf5);
      expect(s.ledger.totalFor(Side.northSouth), 4 * 20);
    });

    test('undo with no deals is rejected', () {
      expect(() => run(newSession(), [const UndoLastDeal()]), throwsInvalid);
    });
  });

  group('Edit a recorded deal', () {
    late SessionState s;
    setUp(() {
      s = newSession(settings(bidding: true));
      s = run(s, [const AdvanceFromStart()]);
      // N deals: P, 1S by E? Simpler: N passes, E 4S... use Carol (S).
      for (final code in ['P', 'P', '4S', 'X', 'P', 'P', 'P']) {
        s = run(s, [RecordCall(Call.fromJson(code))]);
      }
      s = run(s, [
        const ConfirmContract(),
        const FinishPlay(),
        const SetTricks(9),
        const ScoreDeal(),
        const NextDeal(),
      ]);
    });

    test('edit the result', () {
      final r = s.records[0].result!;
      expect(describeResult(r, players.nameOf), '4♠X by Carol · −1');
      final edited = run(s, [EditDeal(0, r.copyWith(tricksTaken: 10))]);
      expect(
        describeResult(edited.records[0].result, players.nameOf),
        '4♠X by Carol · Made',
      );
      // Same contract: the auction stays.
      expect(edited.records[0].auction, isNotNull);
      expect(edited.records[0].auctionEdited, isFalse);
    });

    test('a changed contract replaces the auction', () {
      final r = s.records[0].result!;
      final edited = run(s, [
        EditDeal(
          0,
          r.copyWith(contract: r.contract.copyWith(doubling: Doubling.none)),
        ),
      ]);
      expect(edited.records[0].auction, isNull);
      expect(edited.records[0].auctionEdited, isTrue);
    });

    test('played deal to passed out and back', () {
      final r = s.records[0].result!;
      var e = run(s, [const EditDeal(0, null)]);
      expect(e.records[0].isPassedOut, isTrue);
      expect(e.records[0].dealer, Seat.north);
      expect(e.ledger.totalFor(Side.eastWest), 0);
      e = run(e, [EditDeal(0, r)]);
      expect(e.records[0].result, r);
    });

    test('edit mark keeps the original entry', () {
      final r = s.records[0].result!;
      final t1 = DateTime.utc(2026, 10, 11, 21);
      final t2 = DateTime.utc(2026, 10, 11, 22);
      var e = SessionController.apply(
        s,
        EditDeal(0, r.copyWith(tricksTaken: 10)),
        now: t1,
      );
      e = SessionController.apply(
        e,
        EditDeal(0, r.copyWith(tricksTaken: 11)),
        now: t2,
      );
      final rec = e.records[0];
      expect(rec.isEdited, isTrue);
      expect(
        describeResult(rec.original!.result, players.nameOf),
        '4♠X by Carol · −1',
      );
      expect(rec.editTimes, [t1, t2]);
    });

    test('undo does not keep a mark', () {
      final e = run(s, [const UndoLastDeal()]);
      expect(e.records, isEmpty);
    });
  });

  group('Preview of the effect of an edit', () {
    test('edit changes a later vulnerability', () {
      var s = newSession();
      s = playDeal(s, '4S', Seat.north);
      s = playDeal(s, '1C', Seat.east);
      s = playDeal(s, '3NX', Seat.south, diff: -1);
      expect(s.ledger.deals[2].vulnerability.northSouth, isTrue);
      final r = s.records[0].result!;
      final down = r.copyWith(tricksTaken: 9);
      final preview = SessionController.previewEdit(s, 0, down);
      // Deals 2 and 3 lose the N-S vulnerability.
      expect(preview.changedDeals.map((c) => c.index), [1, 2]);
      final changed = preview.changedDeals.last;
      expect(changed.index, 2);
      expect(changed.vulnerabilityBefore.northSouth, isTrue);
      expect(changed.vulnerabilityAfter.northSouth, isFalse);
      expect(changed.pointsBefore[Side.eastWest], 200);
      expect(changed.pointsAfter[Side.eastWest], 100);
      expect(preview.totalsBefore[Side.northSouth], 120);
      expect(preview.totalsAfter[Side.northSouth], 0);
      // Cancel: the preview does not change the session.
      expect(s.records[0].result, r);
      final saved = run(s, [EditDeal(0, down)]);
      expect(saved.ledger.deals[2].vulnerability.northSouth, isFalse);
    });
  });

  group('Final summary', () {
    test('winner and margin, tie', () {
      var s = playDeal(newSession(), '4S', Seat.north);
      s = run(s, [const EndSession()]);
      final sum = SessionSummary.of(s);
      expect(sum.winner, Side.northSouth);
      expect(sum.margin, 420);
      final tie = run(newSession(), [const EndSession()]);
      expect(SessionSummary.of(tie).winner, isNull);
    });

    test('player statistics', () {
      var s = newSession();
      s = playDeal(s, '1C', Seat.south);
      s = playDeal(s, '1C', Seat.south);
      s = playDeal(s, '6C', Seat.south);
      s = playDeal(s, '2C', Seat.south, diff: -1);
      s = playDeal(s, '2C', Seat.south, diff: -2);
      final carol = SessionSummary.of(s).playerStats
          .firstWhere((p) => p.seat == Seat.south);
      expect(carol.declared, 5);
      expect(carol.fulfilled, 3);
      expect(carol.down, 2);
      expect(carol.slamsBid, 1);
      expect(carol.slamsMade, 1);
    });

    test('biggest deals', () {
      var s = newSession();
      s = playDeal(s, '4H', Seat.east); // E-W game.
      s = playDeal(s, '4S', Seat.north); // N-S game.
      for (var i = 0; i < 4; i++) {
        s = passOut(s);
      }
      s = playDeal(s, '6S', Seat.east); // Deal 7 completes 2–1 for E-W.
      final top = SessionSummary.of(s).biggestDeals.first;
      expect(top.dealNumber, 7);
      expect(top.side, Side.eastWest);
      expect(top.points, 1430);
      expect(describeResult(top.result, players.nameOf), '6♠ by Bob · Made');
    });

    test('chart and target', () {
      var s = newSession(settings(endRule: const TargetScoreRule(5000)));
      s = playDeal(s, '2C', Seat.north);
      s = run(s, [const EndSession()]);
      final sum = SessionSummary.of(s);
      expect(sum.target, 5000);
      expect(sum.chart.map((p) => p.totals[Side.northSouth]), [0, 40]);
      expect(sum.rubbers.single.isComplete, isFalse);
    });
  });

  test('new session with the same players', () {
    var s = newSession(settings(firstDealer: Seat.south));
    s = playDeal(s, '1C', Seat.north); // Dealer South.
    s = playDeal(s, '1C', Seat.north); // Dealer West.
    s = run(s, [const EndSession()]);
    final next = rematchSettings(s);
    expect(next.firstDealer, Seat.north);
    expect(next.players.nameOf(Seat.north), 'Alice');
    expect(next.endRule, s.settings.endRule);
  });

  test('a session keeps its copy of the preset values', () {
    var house = ScoringValues.houseDefaults().withValue(
      ScoringField.rubberTwoNil,
      600,
    );
    var s = newSession(
      settings(preset: ScoringPreset.houseRules, values: house),
    );
    // A later change to House rules makes a new value object.
    house = house.withValue(ScoringField.rubberTwoNil, 800);
    s = playDeal(s, '4S', Seat.north);
    s = playDeal(s, '4S', Seat.north);
    expect(
      s.ledger.deals[1].score.componentTotal(ScoreComponent.rubberBonus),
      600,
    );
    expect(house[ScoringField.rubberTwoNil], 800);
  });

  test('JSON round trip of a session', () {
    var s = newSession(
      settings(bidding: true, components: const ScoringComponents()),
    );
    s = run(s, [const AdvanceFromStart()]);
    for (final code in ['1H', 'P', '4H', 'P', 'P', 'P']) {
      s = run(s, [RecordCall(Call.fromJson(code))]);
    }
    s = run(s, [
      const ConfirmContract(),
      const FinishPlay(),
      const SetTricks(10),
      const SetHonors(Honors(HonorsHolding.fourInOneHand, Side.northSouth)),
      const ScoreDeal(),
      const NextDeal(),
      const AdvanceFromStart(),
      const RecordCall(Call.pass),
    ]);
    s = run(s, [EditDeal(0, s.records[0].result!.copyWith(tricksTaken: 11))]);
    final copy = SessionState.fromJson(jsonDecode(jsonEncode(s.toJson())));
    expect(jsonEncode(copy.toJson()), jsonEncode(s.toJson()));
    expect(copy.draft!.auction!.calls, [Call.pass]);
    expect(copy.records[0].original!.result!.tricksTaken, 10);
  });

  group('Quick entry deals', () {
    SessionSettings quick({EndRule endRule = const DealCountRule(16)}) =>
        settings(endRule: endRule).copyWithQuickEntry(true);
    DealResult r(String code, Seat declarer, {int diff = 0}) {
      final c = contract(code, declarer).toContract()!;
      return DealResult(contract: c, tricksTaken: c.tricksNeeded + diff);
    }

    test('each deal starts at the entry stage', () {
      final s = newSession(quick());
      expect(s.draft!.stage, DealStage.entry);
      expect(
        () => run(s, [const AdvanceFromStart()]),
        throwsA(isA<InvalidCommandException>()),
      );
    });

    test('a quick deal records the same as the full stages', () {
      final quickState = run(newSession(quick()), [
        RecordQuickDeal(r('4SX', Seat.south, diff: -2)),
      ]);
      final full = playDeal(
        newSession(),
        '4SX',
        Seat.south,
        diff: -2,
        next: false,
      );
      expect(quickState.records.single.result, full.records.single.result);
      expect(
        quickState.ledger.totalFor(Side.eastWest),
        full.ledger.totalFor(Side.eastWest),
      );
      expect(quickState.draft!.stage, DealStage.scored);
      final next = run(quickState, [const NextDeal()]);
      expect(next.draft!.stage, DealStage.entry);
      expect(next.draft!.dealer, Seat.east);
    });

    test('a passed-out quick deal', () {
      final s = run(newSession(quick()), [const RecordQuickDeal(null)]);
      expect(s.records.single.isPassedOut, isTrue);
      expect(s.draft!.stage, DealStage.entry);
      expect(s.draft!.dealer, Seat.east);
    });

    test('the end rule still applies', () {
      var s = newSession(quick(endRule: const DealCountRule(2)));
      s = run(s, [RecordQuickDeal(r('1C', Seat.north)), const NextDeal()]);
      s = run(s, [RecordQuickDeal(r('1C', Seat.east))]);
      expect(s.isEnded, isTrue);
      expect(s.endReason, EndReason.endRule);
    });

    test('undo returns to the entry stage', () {
      var s = run(newSession(quick()), [
        RecordQuickDeal(r('1C', Seat.north)),
        const NextDeal(),
        const UndoLastDeal(),
      ]);
      expect(s.records, isEmpty);
      expect(s.draft!.stage, DealStage.entry);
      expect(s.draft!.dealer, Seat.north);
      s = run(s, [const EndSession()]);
      expect(s.isEnded, isTrue);
    });

    test('honors are needed when honors are on', () {
      final s = newSession(
        SessionSettings(
          players: players,
          firstDealer: Seat.north,
          endRule: const DealCountRule(16),
          biddingStep: false,
          components: const ScoringComponents(),
          preset: ScoringPreset.standard,
          values: ScoringValues.standard(),
          quickEntry: true,
        ),
      );
      expect(
        () => run(s, [RecordQuickDeal(r('4H', Seat.south))]),
        throwsA(isA<InvalidCommandException>()),
      );
    });

    test('quick entry has no effect with the bidding step on', () {
      final s = newSession(settings(bidding: true).copyWithQuickEntry(true));
      expect(s.draft!.stage, DealStage.start);
    });
  });

  group('Quick entry setting', () {
    test('JSON round trip', () {
      final s = settings().copyWithQuickEntry(true);
      expect(SessionSettings.fromJson(s.toJson()).quickEntry, isTrue);
      expect(SessionSettings.fromJson(settings().toJson()).quickEntry, isFalse);
    });

    test('an older stored session reads as quick entry off', () {
      final json = settings().toJson()..remove('quickEntry');
      expect(SessionSettings.fromJson(json).quickEntry, isFalse);
    });

    test('new session with the same players keeps quick entry', () {
      var s = newSession(settings().copyWithQuickEntry(true));
      s = run(s, [const EndSession()]);
      expect(rematchSettings(s).quickEntry, isTrue);
    });
  });
}

extension on SessionSettings {
  SessionSettings copyWithQuickEntry(bool value) => SessionSettings(
    players: players,
    firstDealer: firstDealer,
    endRule: endRule,
    biddingStep: biddingStep,
    components: components,
    preset: preset,
    values: values,
    quickEntry: value,
  );
}
