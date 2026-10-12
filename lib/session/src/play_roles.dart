import '../../core/core.dart';
import '../../scoring/scoring.dart';

/// The roles at the play stage.
class PlayRoles {
  const PlayRoles._(this.declarer, this.dummy, this.openingLeader);

  /// The declarer plays the contract, the dummy is the partner of the
  /// declarer, and the player to the left of the declarer makes the opening
  /// lead.
  factory PlayRoles.of(Seat declarer) =>
      PlayRoles._(declarer, declarer.partner, declarer.leftHandOpponent);

  final Seat declarer;
  final Seat dummy;
  final Seat openingLeader;
}

/// One button at the result stage.
class ResultOption {
  const ResultOption(this.label, this.tricksTaken, this.difference);

  /// "Down N", "Made", or "+N".
  final String label;
  final int tricksTaken;

  /// Negative for undertricks, 0 for made, positive for overtricks.
  final int difference;

  /// All possible results for a contract at [level], from "Down (level+6)"
  /// to "+(7 − level)".
  static List<ResultOption> forLevel(int level) {
    final needed = level + 6;
    return [
      for (var tricks = 0; tricks <= 13; tricks++)
        ResultOption(
          tricks == needed
              ? 'Made'
              : tricks > needed
              ? '+${tricks - needed}'
              : 'Down ${needed - tricks}',
          tricks,
          tricks - needed,
        ),
    ];
  }
}

/// Short text of a result for the history, for example
/// "4♠X by Carol · Down 1" or "Passed out".
String describeResult(DealResult? result, String Function(Seat) nameOf) {
  if (result == null) return 'Passed out';
  final c = result.contract;
  return '$c by ${nameOf(c.declarer)} · ${result.shortResult}';
}
