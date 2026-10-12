import '../../auction/auction.dart';
import '../../core/core.dart';
import '../../scoring/scoring.dart';
import 'settings.dart';

/// The stages of one deal, in order.
enum DealStage {
  start('Start'),
  auction('Auction'),
  contract('Contract'),
  play('Play'),
  result('Result'),

  /// The quick-entry screen: contract, result, and honors on one screen.
  entry('Entry'),
  scored('Scored');

  const DealStage(this.label);

  final String label;

  static DealStage fromJson(Object? json) =>
      DealStage.values.byName(json as String);
}

/// The contract values that the user entered so far at the contract stage.
class ContractInput {
  const ContractInput({
    this.level,
    this.strain,
    this.doubling = Doubling.none,
    this.declarer,
  });

  final int? level;
  final Strain? strain;
  final Doubling doubling;
  final Seat? declarer;

  bool get isComplete => level != null && strain != null && declarer != null;

  Contract? toContract() => isComplete
      ? Contract(
          bid: Bid(level!, strain!),
          doubling: doubling,
          declarer: declarer!,
        )
      : null;

  static ContractInput from(Contract c) => ContractInput(
    level: c.level,
    strain: c.strain,
    doubling: c.doubling,
    declarer: c.declarer,
  );

  Map<String, Object?> toJson() => {
    'level': level,
    'strain': strain?.code,
    'doubling': doubling.toJson(),
    'declarer': declarer?.toJson(),
  };

  static ContractInput fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final strain = map['strain'] as String?;
    final declarer = map['declarer'];
    return ContractInput(
      level: map['level'] as int?,
      strain: strain == null ? null : Strain.fromCode(strain),
      doubling: Doubling.fromJson(map['doubling']),
      declarer: declarer == null ? null : Seat.fromJson(declarer),
    );
  }
}

/// The deal that is in progress.
class DealDraft {
  const DealDraft({
    required this.dealer,
    required this.stage,
    this.auction,
    this.contract = const ContractInput(),
    this.tricksTaken,
    this.honors,
  });

  final Seat dealer;
  final DealStage stage;

  /// The auction, only when the bidding step is on.
  final Auction? auction;
  final ContractInput contract;
  final int? tricksTaken;
  final Honors? honors;

  DealDraft copyWith({
    DealStage? stage,
    Auction? auction,
    ContractInput? contract,
    int? Function()? tricksTaken,
    Honors? Function()? honors,
  }) => DealDraft(
    dealer: dealer,
    stage: stage ?? this.stage,
    auction: auction ?? this.auction,
    contract: contract ?? this.contract,
    tricksTaken: tricksTaken == null ? this.tricksTaken : tricksTaken(),
    honors: honors == null ? this.honors : honors(),
  );

  Map<String, Object?> toJson() => {
    'dealer': dealer.toJson(),
    'stage': stage.name,
    'auction': auction?.toJson(),
    'contract': contract.toJson(),
    'tricks': tricksTaken,
    'honors': honors?.toJson(),
  };

  static DealDraft fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final auction = map['auction'];
    final honors = map['honors'];
    return DealDraft(
      dealer: Seat.fromJson(map['dealer']),
      stage: DealStage.fromJson(map['stage']),
      auction: auction == null ? null : Auction.fromJson(auction),
      contract: ContractInput.fromJson(map['contract']),
      tricksTaken: map['tricks'] as int?,
      honors: honors == null ? null : Honors.fromJson(honors),
    );
  }
}

/// The first entry of a deal that the user later edited.
class OriginalEntry {
  const OriginalEntry(this.result);

  /// The first result, or null when the deal was first passed out.
  final DealResult? result;

  Map<String, Object?> toJson() => {'result': result?.toJson()};

  static OriginalEntry fromJson(Object? json) {
    final r = (json as Map<String, Object?>)['result'];
    return OriginalEntry(r == null ? null : DealResult.fromJson(r));
  }
}

/// One recorded deal.
class DealRecord {
  DealRecord({
    required this.dealer,
    required this.result,
    this.auction,
    this.auctionEdited = false,
    this.original,
    List<DateTime> editTimes = const [],
  }) : editTimes = List.unmodifiable(editTimes);

  final Seat dealer;

  /// The result, or null for a passed-out deal.
  final DealResult? result;

  /// The calls, when the bidding step was on and no edit replaced them.
  final Auction? auction;

  /// True when an edit replaced the recorded auction.
  final bool auctionEdited;

  /// The entry as it was first scored, when the deal was edited.
  final OriginalEntry? original;
  final List<DateTime> editTimes;

  bool get isPassedOut => result == null;
  bool get isEdited => original != null;

  Map<String, Object?> toJson() => {
    'dealer': dealer.toJson(),
    'result': result?.toJson(),
    'auction': auction?.toJson(),
    'auctionEdited': auctionEdited,
    'original': original?.toJson(),
    'editTimes': [for (final t in editTimes) t.toUtc().toIso8601String()],
  };

  static DealRecord fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final result = map['result'];
    final auction = map['auction'];
    final original = map['original'];
    return DealRecord(
      dealer: Seat.fromJson(map['dealer']),
      result: result == null ? null : DealResult.fromJson(result),
      auction: auction == null ? null : Auction.fromJson(auction),
      auctionEdited: map['auctionEdited'] as bool,
      original: original == null ? null : OriginalEntry.fromJson(original),
      editTimes: [
        for (final t in map['editTimes'] as List<Object?>)
          DateTime.parse(t as String),
      ],
    );
  }
}

enum SessionStatus { active, ended }

/// Why an ended session ended.
enum EndReason { endRule, early }

/// The full state of one session. Totals, games, and vulnerability are not
/// stored: [ledger] calculates them from the recorded deals.
class SessionState {
  SessionState({
    required this.id,
    required this.createdAt,
    required this.settings,
    required List<DealRecord> records,
    required this.draft,
    required this.status,
    this.endReason,
    this.endedAt,
  }) : records = List.unmodifiable(records);

  final String id;
  final DateTime createdAt;
  final SessionSettings settings;
  final List<DealRecord> records;

  /// The deal in progress. After the last deal of an ended session, it stays
  /// at the scored stage so that the user can see its score.
  final DealDraft? draft;
  final SessionStatus status;
  final EndReason? endReason;
  final DateTime? endedAt;

  bool get isEnded => status == SessionStatus.ended;

  /// The number of the deal in progress, from 1.
  int get currentDealNumber =>
      draft?.stage == DealStage.scored ? records.length : records.length + 1;

  /// The dealer of the deal with [index] (from 0).
  Seat dealerOf(int index) => settings.firstDealer.after(index);

  LedgerSnapshot get ledger => RubberLedger.replay(
    [for (final r in records) r.result],
    settings.values,
    settings.components,
  );

  SessionState copyWith({
    List<DealRecord>? records,
    DealDraft? Function()? draft,
    SessionStatus? status,
    EndReason? Function()? endReason,
    DateTime? Function()? endedAt,
  }) => SessionState(
    id: id,
    createdAt: createdAt,
    settings: settings,
    records: records ?? this.records,
    draft: draft == null ? this.draft : draft(),
    status: status ?? this.status,
    endReason: endReason == null ? this.endReason : endReason(),
    endedAt: endedAt == null ? this.endedAt : endedAt(),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'settings': settings.toJson(),
    'records': [for (final r in records) r.toJson()],
    'draft': draft?.toJson(),
    'status': status.name,
    'endReason': endReason?.name,
    'endedAt': endedAt?.toUtc().toIso8601String(),
  };

  static SessionState fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final draft = map['draft'];
    final endReason = map['endReason'] as String?;
    final endedAt = map['endedAt'] as String?;
    return SessionState(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      settings: SessionSettings.fromJson(map['settings']),
      records: [
        for (final r in map['records'] as List<Object?>) DealRecord.fromJson(r),
      ],
      draft: draft == null ? null : DealDraft.fromJson(draft),
      status: SessionStatus.values.byName(map['status'] as String),
      endReason: endReason == null ? null : EndReason.values.byName(endReason),
      endedAt: endedAt == null ? null : DateTime.parse(endedAt),
    );
  }
}
