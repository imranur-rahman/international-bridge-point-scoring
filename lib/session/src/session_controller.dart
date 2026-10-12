import '../../auction/auction.dart';
import '../../core/core.dart';
import '../../scoring/scoring.dart';
import 'session_state.dart';
import 'settings.dart';

/// Thrown when a command is not valid in the current state.
class InvalidCommandException implements Exception {
  InvalidCommandException(this.message);

  final String message;

  @override
  String toString() => 'InvalidCommandException: $message';
}

/// A command that changes a session.
sealed class SessionCommand {
  const SessionCommand();
}

/// Moves from the deal start to the auction or to the contract stage.
final class AdvanceFromStart extends SessionCommand {
  const AdvanceFromStart();
}

final class RecordCall extends SessionCommand {
  const RecordCall(this.call);
  final Call call;
}

final class UndoCall extends SessionCommand {
  const UndoCall();
}

/// Sets the direct contract entry (only when the bidding step is off).
final class SetContract extends SessionCommand {
  const SetContract(this.input);
  final ContractInput input;
}

final class ConfirmContract extends SessionCommand {
  const ConfirmContract();
}

/// Records a passed-out deal from the contract stage.
final class PassOut extends SessionCommand {
  const PassOut();
}

final class FinishPlay extends SessionCommand {
  const FinishPlay();
}

final class SetTricks extends SessionCommand {
  const SetTricks(this.tricksTaken);
  final int tricksTaken;
}

final class SetHonors extends SessionCommand {
  const SetHonors(this.honors);
  final Honors? honors;
}

final class ScoreDeal extends SessionCommand {
  const ScoreDeal();
}

final class NextDeal extends SessionCommand {
  const NextDeal();
}

/// Returns to the previous stage before the deal is scored.
final class Back extends SessionCommand {
  const Back();
}

final class UndoLastDeal extends SessionCommand {
  const UndoLastDeal();
}

/// Replaces the result of the recorded deal at [index]. A null [result]
/// makes the deal passed out.
final class EditDeal extends SessionCommand {
  const EditDeal(this.index, this.result);
  final int index;
  final DealResult? result;
}

/// Ends the session between deals.
final class EndSession extends SessionCommand {
  const EndSession();
}

/// A later deal whose vulnerability or points change with an edit.
class ChangedDeal {
  const ChangedDeal({
    required this.index,
    required this.vulnerabilityBefore,
    required this.vulnerabilityAfter,
    required this.pointsBefore,
    required this.pointsAfter,
  });

  final int index;
  final Vulnerability vulnerabilityBefore;
  final Vulnerability vulnerabilityAfter;
  final Map<Side, int> pointsBefore;
  final Map<Side, int> pointsAfter;
}

/// The effect of an edit, before it is saved.
class EditPreview {
  const EditPreview({
    required this.totalsBefore,
    required this.totalsAfter,
    required this.changedDeals,
  });

  final Map<Side, int> totalsBefore;
  final Map<Side, int> totalsAfter;
  final List<ChangedDeal> changedDeals;
}

/// Applies commands to a [SessionState]. Pure Dart, with no side effects.
class SessionController {
  const SessionController._();

  /// Starts a session at the deal start of the first deal.
  static SessionState start({
    required String id,
    required DateTime now,
    required SessionSettings settings,
  }) => SessionState(
    id: id,
    createdAt: now,
    settings: settings,
    records: const [],
    draft: DealDraft(dealer: settings.firstDealer, stage: DealStage.start),
    status: SessionStatus.active,
  );

  static SessionState apply(
    SessionState state,
    SessionCommand command, {
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    switch (command) {
      case UndoLastDeal():
        return _undoLastDeal(state);
      case EditDeal(:final index, :final result):
        return _editDeal(state, index, result, time);
      case EndSession():
        return _endSession(state, time);
      default:
        break;
    }

    if (state.isEnded) throw InvalidCommandException('The session has ended');
    final draft = state.draft;
    if (draft == null) throw InvalidCommandException('No deal in progress');
    final settings = state.settings;

    void needStage(DealStage stage) {
      if (draft.stage != stage) {
        throw InvalidCommandException(
          '${command.runtimeType} needs the ${stage.label} stage',
        );
      }
    }

    SessionState withDraft(DealDraft d) => state.copyWith(draft: () => d);

    switch (command) {
      case AdvanceFromStart():
        needStage(DealStage.start);
        return withDraft(
          settings.biddingStep
              ? draft.copyWith(
                  stage: DealStage.auction,
                  auction: draft.auction ?? Auction.start(draft.dealer),
                )
              : draft.copyWith(stage: DealStage.contract),
        );

      case RecordCall(:final call):
        needStage(DealStage.auction);
        final Auction auction;
        try {
          auction = draft.auction!.add(call);
        } on IllegalCallException catch (e) {
          throw InvalidCommandException(e.reason);
        }
        return switch (auction.outcome) {
          InProgress() => withDraft(draft.copyWith(auction: auction)),
          ContractReached(:final contract) => withDraft(
            draft.copyWith(
              auction: auction,
              stage: DealStage.contract,
              contract: ContractInput.from(contract),
            ),
          ),
          PassedOut() => _record(
            state,
            DealRecord(dealer: draft.dealer, result: null, auction: auction),
            time,
          ),
        };

      case UndoCall():
        needStage(DealStage.auction);
        return withDraft(draft.copyWith(auction: draft.auction!.undo()));

      case SetContract(:final input):
        needStage(DealStage.contract);
        if (settings.biddingStep) {
          throw InvalidCommandException(
            'The contract comes from the auction. Go back to change it.',
          );
        }
        return withDraft(draft.copyWith(contract: input));

      case ConfirmContract():
        needStage(DealStage.contract);
        if (!draft.contract.isComplete) {
          throw InvalidCommandException('The contract is not complete');
        }
        return withDraft(draft.copyWith(stage: DealStage.play));

      case PassOut():
        needStage(DealStage.contract);
        if (settings.biddingStep) {
          throw InvalidCommandException('Pass out in the auction');
        }
        return _record(
          state,
          DealRecord(dealer: draft.dealer, result: null),
          time,
        );

      case FinishPlay():
        needStage(DealStage.play);
        return withDraft(draft.copyWith(stage: DealStage.result));

      case SetTricks(:final tricksTaken):
        needStage(DealStage.result);
        if (tricksTaken < 0 || tricksTaken > 13) {
          throw InvalidCommandException('Tricks must be from 0 to 13');
        }
        return withDraft(draft.copyWith(tricksTaken: () => tricksTaken));

      case SetHonors(:final honors):
        needStage(DealStage.result);
        final strain = draft.contract.strain!;
        if (honors != null && honors.holding.suit != strain.isSuit) {
          throw InvalidCommandException('The honors do not fit the contract');
        }
        return withDraft(draft.copyWith(honors: () => honors));

      case ScoreDeal():
        needStage(DealStage.result);
        final result = draftResult(state);
        if (result == null) {
          throw InvalidCommandException(
            settings.components.honors && draft.tricksTaken != null
                ? 'Select the honors'
                : 'Select the result',
          );
        }
        return _record(
          state,
          DealRecord(
            dealer: draft.dealer,
            result: result,
            auction: draft.auction,
          ),
          time,
        );

      case NextDeal():
        needStage(DealStage.scored);
        return withDraft(_newDraft(state, state.records.length));

      case Back():
        final previous = switch (draft.stage) {
          DealStage.auction => DealStage.start,
          DealStage.contract =>
            settings.biddingStep ? DealStage.auction : DealStage.start,
          DealStage.play => DealStage.contract,
          DealStage.result => DealStage.play,
          DealStage.start || DealStage.scored => null,
        };
        if (previous == null) {
          throw InvalidCommandException('No previous stage');
        }
        return withDraft(draft.copyWith(stage: previous));

      case UndoLastDeal() || EditDeal() || EndSession():
        throw StateError('handled above');
    }
  }

  /// The result of the draft, or null when it is not complete.
  static DealResult? draftResult(SessionState state) {
    final draft = state.draft;
    final contract = draft?.contract.toContract();
    final tricks = draft?.tricksTaken;
    if (draft == null || contract == null || tricks == null) return null;
    final honorsOn = state.settings.components.honors;
    if (honorsOn && draft.honors == null) return null;
    return DealResult(
      contract: contract,
      tricksTaken: tricks,
      honors: honorsOn ? draft.honors : null,
    );
  }

  static DealDraft _newDraft(SessionState state, int index) =>
      DealDraft(dealer: state.dealerOf(index), stage: DealStage.start);

  static SessionState _record(
    SessionState state,
    DealRecord record,
    DateTime now,
  ) {
    final records = [...state.records, record];
    final next = state.copyWith(records: records);
    final reached = state.settings.endRule.isReached(
      next.ledger,
      records.length,
    );
    final DealDraft? draft = record.isPassedOut
        ? (reached ? null : _newDraft(next, records.length))
        : state.draft!.copyWith(stage: DealStage.scored);
    return next.copyWith(
      draft: () => draft,
      status: reached ? SessionStatus.ended : SessionStatus.active,
      endReason: () => reached ? EndReason.endRule : null,
      endedAt: () => reached ? now : null,
    );
  }

  static SessionState _undoLastDeal(SessionState state) {
    if (state.records.isEmpty) {
      throw InvalidCommandException('No deal to undo');
    }
    final index = state.records.length - 1;
    final records = state.records.sublist(0, index);
    final next = state.copyWith(records: records);
    if (state.isEnded) {
      final stillReached =
          state.endReason == EndReason.early ||
          state.settings.endRule.isReached(next.ledger, records.length);
      if (stillReached) return next.copyWith(draft: () => null);
    }
    return next.copyWith(
      draft: () => _newDraft(next, index),
      status: SessionStatus.active,
      endReason: () => null,
      endedAt: () => null,
    );
  }

  static List<DealRecord> _replaceRecord(
    SessionState state,
    int index,
    DealResult? result,
    DateTime now,
  ) {
    final old = state.records[index];
    final contractChanged = old.result?.contract != result?.contract;
    final replaceAuction = old.auction != null && contractChanged;
    final record = DealRecord(
      dealer: old.dealer,
      result: result,
      auction: replaceAuction ? null : old.auction,
      auctionEdited: old.auctionEdited || replaceAuction,
      original: old.original ?? OriginalEntry(old.result),
      editTimes: [...old.editTimes, now],
    );
    return [...state.records]..[index] = record;
  }

  static SessionState _editDeal(
    SessionState state,
    int index,
    DealResult? result,
    DateTime now,
  ) {
    if (index < 0 || index >= state.records.length) {
      throw InvalidCommandException('No recorded deal $index');
    }
    if (result != null &&
        state.settings.components.honors &&
        result.honors == null) {
      throw InvalidCommandException('Select the honors');
    }
    final records = _replaceRecord(state, index, result, now);
    final next = state.copyWith(records: records);
    final reached = state.settings.endRule.isReached(
      next.ledger,
      records.length,
    );
    if (state.isEnded) {
      if (state.endReason == EndReason.endRule && !reached) {
        return next.copyWith(
          draft: () => _newDraft(next, records.length),
          status: SessionStatus.active,
          endReason: () => null,
          endedAt: () => null,
        );
      }
      return next;
    }
    if (reached) {
      final draft = state.draft;
      return next.copyWith(
        draft: () => draft?.stage == DealStage.scored ? draft : null,
        status: SessionStatus.ended,
        endReason: () => EndReason.endRule,
        endedAt: () => now,
      );
    }
    return next;
  }

  static SessionState _endSession(SessionState state, DateTime now) {
    if (state.isEnded) throw InvalidCommandException('Already ended');
    final draft = state.draft;
    if (draft != null &&
        draft.stage != DealStage.start &&
        draft.stage != DealStage.scored) {
      throw InvalidCommandException('End the session between deals');
    }
    return state.copyWith(
      draft: () => draft?.stage == DealStage.scored ? draft : null,
      status: SessionStatus.ended,
      endReason: () => EndReason.early,
      endedAt: () => now,
    );
  }

  /// The effect of an edit of the deal at [index], without a change to
  /// [state].
  static EditPreview previewEdit(
    SessionState state,
    int index,
    DealResult? result,
  ) {
    final before = state.ledger;
    final records = _replaceRecord(state, index, result, DateTime.now());
    final after = state.copyWith(records: records).ledger;
    Map<Side, int> totals(LedgerSnapshot s) => {
      for (final side in Side.values) side: s.totalFor(side),
    };
    final changed = <ChangedDeal>[];
    for (var i = index + 1; i < records.length; i++) {
      final b = before.deals[i];
      final a = after.deals[i];
      final pb = {for (final s in Side.values) s: b.score.totalFor(s)};
      final pa = {for (final s in Side.values) s: a.score.totalFor(s)};
      final pointsChanged = Side.values.any((s) => pb[s] != pa[s]);
      if (b.vulnerability != a.vulnerability || pointsChanged) {
        changed.add(
          ChangedDeal(
            index: i,
            vulnerabilityBefore: b.vulnerability,
            vulnerabilityAfter: a.vulnerability,
            pointsBefore: pb,
            pointsAfter: pa,
          ),
        );
      }
    }
    return EditPreview(
      totalsBefore: totals(before),
      totalsAfter: totals(after),
      changedDeals: changed,
    );
  }
}
