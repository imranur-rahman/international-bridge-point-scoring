/// One of the two partnerships.
enum Side {
  northSouth,
  eastWest;

  Side get opponent => this == northSouth ? eastWest : northSouth;

  /// The two seats of this side, in seat order.
  List<Seat> get seats => this == northSouth
      ? const [Seat.north, Seat.south]
      : const [Seat.east, Seat.west];

  static Side fromJson(Object? json) => Side.values.byName(json as String);
  String toJson() => name;
}

/// The four seats at the table, in clockwise order.
///
/// Player 1 sits North, player 2 East, player 3 South, and player 4 West.
enum Seat {
  north('N', 'North'),
  east('E', 'East'),
  south('S', 'South'),
  west('W', 'West');

  const Seat(this.letter, this.label);

  final String letter;
  final String label;

  /// The next seat clockwise.
  Seat get next => Seat.values[(index + 1) % 4];

  /// The previous seat clockwise.
  Seat get previous => Seat.values[(index + 3) % 4];

  Seat get partner => Seat.values[(index + 2) % 4];

  /// The player to the left of this seat. This player makes the opening lead
  /// when this seat is the declarer.
  Seat get leftHandOpponent => next;

  Side get side => index.isEven ? Side.northSouth : Side.eastWest;

  /// The seat [steps] places clockwise from this seat.
  Seat after(int steps) => Seat.values[(index + steps) % 4];

  static Seat fromJson(Object? json) => Seat.values.byName(json as String);
  String toJson() => name;
}
