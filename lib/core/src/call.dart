import 'bid.dart';

/// The kinds of call in an auction.
enum CallKind { bid, pass, double, redouble }

/// One call in an auction: a bid, a pass, a double, or a redouble.
class Call {
  const Call._(this.kind, this.bid);

  Call.bid(Bid this.bid) : kind = CallKind.bid;

  static const Call pass = Call._(CallKind.pass, null);
  static const Call double = Call._(CallKind.double, null);
  static const Call redouble = Call._(CallKind.redouble, null);

  final CallKind kind;

  /// The bid, only when [kind] is [CallKind.bid].
  final Bid? bid;

  bool get isBid => kind == CallKind.bid;
  bool get isPass => kind == CallKind.pass;

  @override
  bool operator ==(Object other) =>
      other is Call && other.kind == kind && other.bid == bid;

  @override
  int get hashCode => Object.hash(kind, bid);

  @override
  String toString() => switch (kind) {
    CallKind.bid => bid.toString(),
    CallKind.pass => 'Pass',
    CallKind.double => 'X',
    CallKind.redouble => 'XX',
  };

  /// Compact JSON form: "1C" to "7N", "P", "X", or "XX".
  String toJson() => switch (kind) {
    CallKind.bid => bid!.toJson(),
    CallKind.pass => 'P',
    CallKind.double => 'X',
    CallKind.redouble => 'XX',
  };

  static Call fromJson(Object? json) => switch (json as String) {
    'P' => pass,
    'X' => double,
    'XX' => redouble,
    final s => Call.bid(Bid.fromJson(s)),
  };
}
