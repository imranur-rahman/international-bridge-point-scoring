/// The denomination of a bid, in rank order from lowest to highest.
enum Strain {
  clubs('♣', 'C'),
  diamonds('♦', 'D'),
  hearts('♥', 'H'),
  spades('♠', 'S'),
  noTrump('NT', 'N');

  const Strain(this.symbol, this.code);

  final String symbol;

  /// One-letter code for the compact JSON form.
  final String code;

  bool get isMinor => this == clubs || this == diamonds;
  bool get isMajor => this == hearts || this == spades;
  bool get isSuit => this != noTrump;

  static Strain fromCode(String code) =>
      Strain.values.firstWhere((s) => s.code == code);
}
