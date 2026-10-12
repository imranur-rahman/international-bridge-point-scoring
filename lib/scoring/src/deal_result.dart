import '../../core/core.dart';
import 'scoring_values.dart';

/// The honors holding of the majority side (the side with 3 or more honors).
enum HonorsHolding {
  // Suit contracts: the A, K, Q, J, and 10 of trumps.
  threeHonors('3 honors', suit: true, count: 3, inOneHand: 0),
  fourSplit('4 honors, split', suit: true, count: 4, inOneHand: 0),
  fourInOneHand('4 honors in one hand', suit: true, count: 4, inOneHand: 4),
  fiveSplit('5 honors, split 3 + 2', suit: true, count: 5, inOneHand: 0),
  fourPlusOne('5 honors, 4 + 1', suit: true, count: 5, inOneHand: 4),
  fiveInOneHand('5 honors in one hand', suit: true, count: 5, inOneHand: 5),

  // No trump contracts: the four aces.
  noneTwoTwo('None (2 + 2)', suit: false, count: 0, inOneHand: 0),
  threeAces('3 aces', suit: false, count: 3, inOneHand: 0),
  fourAcesSplit('4 aces, split', suit: false, count: 4, inOneHand: 0),
  fourAcesInOneHand('4 aces in one hand', suit: false, count: 4, inOneHand: 4);

  const HonorsHolding(
    this.label, {
    required this.suit,
    required this.count,
    required this.inOneHand,
  });

  final String label;

  /// True for a suit contract holding, false for a no trump holding.
  final bool suit;

  /// The number of honors (or aces) that the majority side holds.
  final int count;

  /// 4 or 5 when one hand holds that many, or 0.
  final int inOneHand;

  /// True when no side scores honors.
  bool get isNone => this == noneTwoTwo;

  /// The holdings that are possible for a contract in [strain].
  static List<HonorsHolding> forStrain(Strain strain) =>
      values.where((h) => h.suit == strain.isSuit).toList();

  /// The honors points of this holding with [values].
  int points(ScoringValues values) {
    if (isNone) return 0;
    final ScoringField handField;
    final ScoringField otherField;
    if (suit) {
      handField = inOneHand == 5
          ? ScoringField.honorsFiveInOneHand
          : ScoringField.honorsFourInOneHand;
      otherField = ScoringField.honorsEachOther;
    } else {
      handField = ScoringField.acesFourInOneHand;
      otherField = ScoringField.acesEachOther;
    }
    final handPoints = inOneHand > 0 ? values[handField] : 0;
    return handPoints + (count - inOneHand) * values[otherField];
  }

  static HonorsHolding fromJson(Object? json) =>
      HonorsHolding.values.byName(json as String);
  String toJson() => name;
}

/// The honors of one deal: the majority side and its holding.
class Honors {
  const Honors(this.holding, [this.side])
    : assert(side != null || holding == HonorsHolding.noneTwoTwo);

  /// No side scores honors (each side holds 2 aces at no trump).
  static const Honors none = Honors(HonorsHolding.noneTwoTwo);

  final HonorsHolding holding;

  /// The majority side, or null for [none].
  final Side? side;

  @override
  bool operator ==(Object other) =>
      other is Honors && other.holding == holding && other.side == side;

  @override
  int get hashCode => Object.hash(holding, side);

  Map<String, Object?> toJson() => {
    'holding': holding.toJson(),
    'side': side?.toJson(),
  };

  static Honors fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final side = map['side'];
    return Honors(
      HonorsHolding.fromJson(map['holding']),
      side == null ? null : Side.fromJson(side),
    );
  }
}

/// The result of one played deal.
class DealResult {
  DealResult({required this.contract, required this.tricksTaken, this.honors}) {
    if (tricksTaken < 0 || tricksTaken > 13) {
      throw ArgumentError.value(tricksTaken, 'tricksTaken', 'must be 0 to 13');
    }
    final h = honors;
    if (h != null && h.holding.suit != contract.strain.isSuit) {
      throw ArgumentError.value(h.holding, 'honors', 'does not fit the strain');
    }
  }

  final Contract contract;

  /// The tricks that the declarer took, from 0 to 13.
  final int tricksTaken;

  /// The honors, or null when honors are not recorded.
  final Honors? honors;

  bool get isFulfilled => tricksTaken >= contract.tricksNeeded;

  /// Positive for overtricks, negative for undertricks, 0 for exactly made.
  int get difference => tricksTaken - contract.tricksNeeded;

  int get overtricks => difference > 0 ? difference : 0;
  int get undertricks => difference < 0 ? -difference : 0;

  /// Short text in bridge words: "Made", "+2", or "Down 1".
  String get shortResult => difference == 0
      ? 'Made'
      : difference > 0
      ? '+$difference'
      : 'Down ${-difference}';

  /// Full text in bridge words.
  String get fullResult {
    if (difference == 0) return 'Contract fulfilled';
    if (difference > 0) {
      return 'Contract fulfilled with $difference '
          '${difference == 1 ? 'overtrick' : 'overtricks'}';
    }
    final n = -difference;
    return 'Down $n ($n ${n == 1 ? 'undertrick' : 'undertricks'})';
  }

  DealResult copyWith({Contract? contract, int? tricksTaken, Honors? honors}) =>
      DealResult(
        contract: contract ?? this.contract,
        tricksTaken: tricksTaken ?? this.tricksTaken,
        honors: honors ?? this.honors,
      );

  @override
  bool operator ==(Object other) =>
      other is DealResult &&
      other.contract == contract &&
      other.tricksTaken == tricksTaken &&
      other.honors == honors;

  @override
  int get hashCode => Object.hash(contract, tricksTaken, honors);

  Map<String, Object?> toJson() => {
    'contract': contract.toJson(),
    'tricks': tricksTaken,
    'honors': honors?.toJson(),
  };

  static DealResult fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    final honors = map['honors'];
    return DealResult(
      contract: Contract.fromJson(map['contract']),
      tricksTaken: map['tricks'] as int,
      honors: honors == null ? null : Honors.fromJson(honors),
    );
  }
}
