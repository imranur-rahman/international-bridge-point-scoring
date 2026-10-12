import 'strain.dart';

/// A bid: a level from 1 to 7 and a strain.
class Bid implements Comparable<Bid> {
  Bid(this.level, this.strain) {
    if (level < 1 || level > 7) {
      throw ArgumentError.value(level, 'level', 'must be from 1 to 7');
    }
  }

  final int level;
  final Strain strain;

  /// 0 for 1♣ up to 34 for 7NT.
  int get rank => (level - 1) * Strain.values.length + strain.index;

  bool isHigherThan(Bid other) => rank > other.rank;

  /// The number of tricks the declarer needs: level + 6.
  int get tricksNeeded => level + 6;

  /// All 35 bids from 1♣ to 7NT, in rank order.
  static final List<Bid> all = [
    for (var level = 1; level <= 7; level++)
      for (final strain in Strain.values) Bid(level, strain),
  ];

  @override
  int compareTo(Bid other) => rank.compareTo(other.rank);

  @override
  bool operator ==(Object other) =>
      other is Bid && other.level == level && other.strain == strain;

  @override
  int get hashCode => Object.hash(level, strain);

  /// Text form, for example "4♠" or "3NT".
  @override
  String toString() => '$level${strain.symbol}';

  /// Compact JSON form, for example "4S" or "3N".
  String toJson() => '$level${strain.code}';

  static Bid fromJson(Object? json) {
    final s = json as String;
    return Bid(int.parse(s.substring(0, 1)), Strain.fromCode(s.substring(1)));
  }
}
