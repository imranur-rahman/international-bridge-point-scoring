import '../../core/core.dart';

/// The four players by seat. Player 1 sits North, 2 East, 3 South, 4 West.
class Players {
  Players(Map<Seat, String> names)
    : names = Map.unmodifiable({
        for (final seat in Seat.values) seat: names[seat]!.trim(),
      });

  final Map<Seat, String> names;

  String nameOf(Seat seat) => names[seat]!;

  /// The name of a partnership, for example "Alice & Carol".
  String partnershipName(Side side) =>
      '${nameOf(side.seats[0])} & ${nameOf(side.seats[1])}';

  /// Errors by seat for the raw names that a user entered. Empty when all
  /// names are valid.
  static Map<Seat, String> validate(Map<Seat, String> raw) {
    final errors = <Seat, String>{};
    final seen = <String, Seat>{};
    for (final seat in Seat.values) {
      final name = (raw[seat] ?? '').trim();
      if (name.isEmpty) {
        errors[seat] = 'Enter a name';
        continue;
      }
      final key = name.toLowerCase();
      if (seen.containsKey(key)) {
        errors[seat] = 'Each player needs a different name';
      } else {
        seen[key] = seat;
      }
    }
    return errors;
  }

  Map<String, Object?> toJson() => {
    for (final seat in Seat.values) seat.name: nameOf(seat),
  };

  static Players fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return Players({
      for (final seat in Seat.values) seat: map[seat.name] as String,
    });
  }
}
