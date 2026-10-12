import '../../core/core.dart';

/// Thrown when a call is not legal at the current point of the auction.
class IllegalCallException implements Exception {
  IllegalCallException(this.call, this.reason);

  final Call call;
  final String reason;

  @override
  String toString() => 'IllegalCallException: $call is not legal ($reason)';
}

/// The result of an auction.
sealed class AuctionOutcome {
  const AuctionOutcome();
}

/// The auction continues.
final class InProgress extends AuctionOutcome {
  const InProgress();
}

/// The first four calls were passes.
final class PassedOut extends AuctionOutcome {
  const PassedOut();
}

/// Three passes followed a bid, a double, or a redouble.
final class ContractReached extends AuctionOutcome {
  const ContractReached(this.contract);

  final Contract contract;
}

/// An immutable auction: the dealer and the calls in order.
class Auction {
  Auction._(this.dealer, List<Call> calls) : calls = List.unmodifiable(calls);

  /// Starts a new auction. The first call belongs to [dealer].
  factory Auction.start(Seat dealer) => Auction._(dealer, const []);

  /// Builds an auction from recorded calls. Throws [IllegalCallException]
  /// when a call is not legal.
  factory Auction.fromCalls(Seat dealer, Iterable<Call> calls) {
    var auction = Auction.start(dealer);
    for (final call in calls) {
      auction = auction.add(call);
    }
    return auction;
  }

  final Seat dealer;
  final List<Call> calls;

  /// The seat that made the call at [index].
  Seat seatOf(int index) => dealer.after(index);

  bool get isComplete => outcome is! InProgress;

  /// The player to call, or null when the auction ended.
  Seat? get toCall => isComplete ? null : dealer.after(calls.length);

  int get _lastBidIndex => calls.lastIndexWhere((c) => c.isBid);

  /// The last bid of the auction, or null if no player bid.
  Bid? get lastBid {
    final i = _lastBidIndex;
    return i < 0 ? null : calls[i].bid;
  }

  /// The index of the last call that is not a pass, or -1.
  int get _lastActionIndex => calls.lastIndexWhere((c) => !c.isPass);

  AuctionOutcome get outcome {
    if (calls.length >= 4 && calls.every((c) => c.isPass)) {
      return const PassedOut();
    }
    final hasBid = _lastBidIndex >= 0;
    if (hasBid &&
        calls.length >= 4 &&
        calls.sublist(calls.length - 3).every((c) => c.isPass)) {
      return ContractReached(_finalContract());
    }
    return const InProgress();
  }

  Contract _finalContract() {
    final bidIndex = _lastBidIndex;
    final bid = calls[bidIndex].bid!;
    final side = seatOf(bidIndex).side;
    final after = calls.sublist(bidIndex + 1);
    final doubling = after.any((c) => c.kind == CallKind.redouble)
        ? Doubling.redoubled
        : after.any((c) => c.kind == CallKind.double)
        ? Doubling.doubled
        : Doubling.none;
    // The declarer is the first player of the side that made the last bid
    // who bid the strain of the final contract.
    late Seat declarer;
    for (var i = 0; i <= bidIndex; i++) {
      final c = calls[i];
      if (c.isBid && c.bid!.strain == bid.strain && seatOf(i).side == side) {
        declarer = seatOf(i);
        break;
      }
    }
    return Contract(bid: bid, doubling: doubling, declarer: declarer);
  }

  /// Returns null when [call] is legal, or the reason why it is not.
  String? whyIllegal(Call call) {
    final seat = toCall;
    if (seat == null) return 'the auction has ended';
    switch (call.kind) {
      case CallKind.pass:
        return null;
      case CallKind.bid:
        final last = lastBid;
        if (last != null && !call.bid!.isHigherThan(last)) {
          return 'a bid must be higher than $last';
        }
        return null;
      case CallKind.double:
        final i = _lastActionIndex;
        if (i < 0 || !calls[i].isBid) {
          return 'only a bid can be doubled';
        }
        if (seatOf(i).side == seat.side) {
          return 'only a bid of an opponent can be doubled';
        }
        return null;
      case CallKind.redouble:
        final i = _lastActionIndex;
        if (i < 0 || calls[i].kind != CallKind.double) {
          return 'only a double can be redoubled';
        }
        if (seatOf(i).side == seat.side) {
          return 'only a double of an opponent can be redoubled';
        }
        return null;
    }
  }

  bool isLegal(Call call) => whyIllegal(call) == null;

  /// All legal calls for the player to call. Empty when the auction ended.
  Set<Call> legalCalls() {
    if (isComplete) return const {};
    return {
      Call.pass,
      Call.double,
      Call.redouble,
      for (final bid in Bid.all) Call.bid(bid),
    }.where(isLegal).toSet();
  }

  /// Returns a new auction with [call] added.
  Auction add(Call call) {
    final reason = whyIllegal(call);
    if (reason != null) throw IllegalCallException(call, reason);
    return Auction._(dealer, [...calls, call]);
  }

  /// Returns the auction without its last call.
  Auction undo() {
    if (calls.isEmpty) return this;
    return Auction._(dealer, calls.sublist(0, calls.length - 1));
  }

  /// The order of the columns in [rounds]: West, North, East, South.
  static const List<Seat> columnOrder = [
    Seat.west,
    Seat.north,
    Seat.east,
    Seat.south,
  ];

  /// The calls as a grid with one column for each seat in [columnOrder].
  /// A cell is null before the dealer's first call and after the last call.
  List<List<Call?>> rounds() {
    final offset = columnOrder.indexOf(dealer);
    final cells = <Call?>[for (var i = 0; i < offset; i++) null, ...calls];
    final rows = <List<Call?>>[];
    for (var i = 0; i < cells.length; i += 4) {
      rows.add([
        for (var j = 0; j < 4; j++) i + j < cells.length ? cells[i + j] : null,
      ]);
    }
    return rows;
  }

  Map<String, Object?> toJson() => {
    'dealer': dealer.toJson(),
    'calls': [for (final c in calls) c.toJson()],
  };

  static Auction fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return Auction.fromCalls(
      Seat.fromJson(map['dealer']),
      (map['calls'] as List<Object?>).map(Call.fromJson),
    );
  }
}
