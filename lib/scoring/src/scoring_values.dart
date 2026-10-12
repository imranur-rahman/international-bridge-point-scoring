/// The groups of scoring values, in screen order.
enum ScoringGroup {
  trickValues('Trick values'),
  doubleRedouble('Double and redouble'),
  game('Game'),
  slams('Slams'),
  undertricks('Undertricks (penalties)'),
  honors('Honors'),
  rubber('Rubber');

  const ScoringGroup(this.label);

  final String label;
}

/// One configurable scoring value, with its two defaults.
///
/// The defaults come from the "Scoring values table" requirement of the
/// rubber-scoring spec.
enum ScoringField {
  minorTrick(ScoringGroup.trickValues, '♣ / ♦ each trick', 20, 20),
  majorTrick(ScoringGroup.trickValues, '♥ / ♠ each trick', 30, 30),
  noTrumpFirstTrick(ScoringGroup.trickValues, 'NT first trick', 40, 40),
  noTrumpLaterTrick(ScoringGroup.trickValues, 'NT each later trick', 30, 30),

  doubleMultiplier(
    ScoringGroup.doubleRedouble,
    'Doubled contract points ×',
    2,
    2,
  ),
  redoubleMultiplier(
    ScoringGroup.doubleRedouble,
    'Redoubled contract points ×',
    4,
    4,
  ),
  overtrickDoubledNotVulnerable(
    ScoringGroup.doubleRedouble,
    'Doubled overtrick, not vulnerable',
    100,
    100,
  ),
  overtrickDoubledVulnerable(
    ScoringGroup.doubleRedouble,
    'Doubled overtrick, vulnerable',
    200,
    200,
  ),
  insultDoubled(ScoringGroup.doubleRedouble, 'Insult bonus, doubled', 50, 50),
  insultRedoubled(
    ScoringGroup.doubleRedouble,
    'Insult bonus, redoubled',
    100,
    100,
  ),

  gameThreshold(ScoringGroup.game, 'Game threshold', 100, 100, minimum: 1),
  gameBonusNotVulnerable(ScoringGroup.game, 'Game bonus, not vulnerable', 0, 0),
  gameBonusVulnerable(ScoringGroup.game, 'Game bonus, vulnerable', 0, 0),

  smallSlamNotVulnerable(
    ScoringGroup.slams,
    'Small slam, not vulnerable',
    500,
    500,
  ),
  smallSlamVulnerable(ScoringGroup.slams, 'Small slam, vulnerable', 750, 750),
  grandSlamNotVulnerable(
    ScoringGroup.slams,
    'Grand slam, not vulnerable',
    1000,
    1000,
  ),
  grandSlamVulnerable(ScoringGroup.slams, 'Grand slam, vulnerable', 1500, 1500),

  undertrickUndoubledNotVulnerable(
    ScoringGroup.undertricks,
    'Undoubled, not vulnerable, each',
    50,
    50,
  ),
  undertrickUndoubledVulnerable(
    ScoringGroup.undertricks,
    'Undoubled, vulnerable, each',
    100,
    100,
  ),
  undertrickDoubledNotVulnerableFirst(
    ScoringGroup.undertricks,
    'Doubled, not vulnerable, 1st',
    100,
    100,
  ),
  undertrickDoubledNotVulnerableSecondThird(
    ScoringGroup.undertricks,
    'Doubled, not vulnerable, 2nd and 3rd each',
    200,
    200,
  ),
  undertrickDoubledNotVulnerableFourthOn(
    ScoringGroup.undertricks,
    'Doubled, not vulnerable, 4th and later each',
    300,
    300,
  ),
  undertrickDoubledVulnerableFirst(
    ScoringGroup.undertricks,
    'Doubled, vulnerable, 1st',
    200,
    200,
  ),
  undertrickDoubledVulnerableSecondThird(
    ScoringGroup.undertricks,
    'Doubled, vulnerable, 2nd and 3rd each',
    300,
    300,
  ),
  undertrickDoubledVulnerableFourthOn(
    ScoringGroup.undertricks,
    'Doubled, vulnerable, 4th and later each',
    300,
    300,
  ),

  honorsFourInOneHand(
    ScoringGroup.honors,
    '4 trump honors in one hand',
    100,
    80,
  ),
  honorsFiveInOneHand(
    ScoringGroup.honors,
    '5 trump honors in one hand',
    150,
    100,
  ),
  honorsEachOther(
    ScoringGroup.honors,
    'Each other honor of the majority side',
    0,
    10,
  ),
  acesFourInOneHand(ScoringGroup.honors, '4 aces in one hand (NT)', 150, 80),
  acesEachOther(
    ScoringGroup.honors,
    'Each other ace of the majority side (NT)',
    0,
    10,
  ),

  rubberTwoNil(ScoringGroup.rubber, 'Rubber won 2 games to 0', 700, 250),
  rubberTwoOne(ScoringGroup.rubber, 'Rubber won 2 games to 1', 500, 250),
  unfinishedOneGame(
    ScoringGroup.rubber,
    'Unfinished rubber, one game won',
    300,
    125,
  ),
  unfinishedPartScore(
    ScoringGroup.rubber,
    'Unfinished rubber, part-score',
    100,
    0,
  );

  const ScoringField(
    this.group,
    this.label,
    this.standardDefault,
    this.houseDefault, {
    this.minimum = 0,
  });

  final ScoringGroup group;
  final String label;
  final int standardDefault;
  final int houseDefault;
  final int minimum;

  static const int maximum = 100000;

  static List<ScoringField> inGroup(ScoringGroup group) =>
      values.where((f) => f.group == group).toList();
}

/// The two scoring presets.
enum ScoringPreset {
  standard('Standard'),
  houseRules('House rules');

  const ScoringPreset(this.label);

  final String label;

  static ScoringPreset fromJson(Object? json) =>
      ScoringPreset.values.byName(json as String);
  String toJson() => name;
}

/// An immutable set of values for all 34 scoring fields.
class ScoringValues {
  ScoringValues._(Map<ScoringField, int> values)
    : _values = Map.unmodifiable(values);

  /// The values of the Laws of Contract Bridge for rubber bridge, plus a
  /// game bonus of 0.
  factory ScoringValues.standard() => ScoringValues._({
    for (final f in ScoringField.values) f: f.standardDefault,
  });

  /// The defaults of the "House rules" preset.
  factory ScoringValues.houseDefaults() =>
      ScoringValues._({for (final f in ScoringField.values) f: f.houseDefault});

  final Map<ScoringField, int> _values;

  int operator [](ScoringField field) => _values[field]!;

  ScoringValues withValue(ScoringField field, int value) =>
      ScoringValues._({..._values, field: value});

  /// Field errors. Empty when all values are valid.
  Map<ScoringField, String> validate() => {
    for (final f in ScoringField.values)
      if (this[f] < f.minimum || this[f] > ScoringField.maximum)
        f: 'Enter a whole number from ${f.minimum} to ${ScoringField.maximum}',
  };

  bool get isValid => validate().isEmpty;

  /// The fields whose value is different in [other].
  Set<ScoringField> differsFrom(ScoringValues other) => {
    for (final f in ScoringField.values)
      if (this[f] != other[f]) f,
  };

  @override
  bool operator ==(Object other) =>
      other is ScoringValues && differsFrom(other).isEmpty;

  @override
  int get hashCode =>
      Object.hashAll([for (final f in ScoringField.values) this[f]]);

  Map<String, Object?> toJson() => {
    for (final f in ScoringField.values) f.name: this[f],
  };

  /// Reads values from JSON. A missing field takes its standard default, so
  /// that older stored data stays readable.
  static ScoringValues fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return ScoringValues._({
      for (final f in ScoringField.values)
        f: (map[f.name] as int?) ?? f.standardDefault,
    });
  }
}

/// The optional scoring components of a session.
class ScoringComponents {
  const ScoringComponents({
    this.honors = true,
    this.unfinishedRubberBonus = true,
  });

  final bool honors;
  final bool unfinishedRubberBonus;

  ScoringComponents copyWith({bool? honors, bool? unfinishedRubberBonus}) =>
      ScoringComponents(
        honors: honors ?? this.honors,
        unfinishedRubberBonus:
            unfinishedRubberBonus ?? this.unfinishedRubberBonus,
      );

  @override
  bool operator ==(Object other) =>
      other is ScoringComponents &&
      other.honors == honors &&
      other.unfinishedRubberBonus == unfinishedRubberBonus;

  @override
  int get hashCode => Object.hash(honors, unfinishedRubberBonus);

  Map<String, Object?> toJson() => {
    'honors': honors,
    'unfinishedRubberBonus': unfinishedRubberBonus,
  };

  static ScoringComponents fromJson(Object? json) {
    final map = json as Map<String, Object?>;
    return ScoringComponents(
      honors: map['honors'] as bool,
      unfinishedRubberBonus: map['unfinishedRubberBonus'] as bool,
    );
  }
}
