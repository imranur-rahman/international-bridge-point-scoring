import 'bid.dart';
import 'seat.dart';
import 'strain.dart';

/// Whether a contract is undoubled, doubled, or redoubled.
enum Doubling {
  none(''),
  doubled('X'),
  redoubled('XX');

  const Doubling(this.mark);

  /// Short mark after the contract, for example "4♠X".
  final String mark;

  static Doubling fromJson(Object? json) =>
      Doubling.values.byName(json as String);
  String toJson() => name;
}

/// A final contract with its declarer.
class Contract {
  const Contract({
    required this.bid,
    required this.doubling,
    required this.declarer,
  });

  final Bid bid;
  final Doubling doubling;
  final Seat declarer;

  int get level => bid.level;
  Strain get strain => bid.strain;
  int get tricksNeeded => bid.tricksNeeded;
  Side get declaringSide => declarer.side;

  Contract copyWith({Bid? bid, Doubling? doubling, Seat? declarer}) => Contract(
    bid: bid ?? this.bid,
    doubling: doubling ?? this.doubling,
    declarer: declarer ?? this.declarer,
  );

  @override
  bool operator ==(Object other) =>
      other is Contract &&
      other.bid == bid &&
      other.doubling == doubling &&
      other.declarer == declarer;

  @override
  int get hashCode => Object.hash(bid, doubling, declarer);

  /// Text form without the declarer, for example "4♠X".
  @override
  String toString() => '$bid${doubling.mark}';

  Map<String, Object?> toJson() => {
    'bid': bid.toJson(),
    'doubling': doubling.toJson(),
    'declarer': declarer.toJson(),
  };

  static Contract fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return Contract(
      bid: Bid.fromJson(map['bid']),
      doubling: Doubling.fromJson(map['doubling']),
      declarer: Seat.fromJson(map['declarer']),
    );
  }
}
