/// The theme mode setting.
enum ThemeModeSetting {
  system('System'),
  light('Light'),
  dark('Dark');

  const ThemeModeSetting(this.label);
  final String label;
}

/// The app text size, applied in addition to the device text size.
enum TextSizeSetting {
  normal('Normal', 1.0),
  large('Large', 1.2),
  extraLarge('Extra large', 1.4);

  const TextSizeSetting(this.label, this.scale);
  final String label;
  final double scale;
}

enum SuitColorsSetting {
  two('Two colors'),
  four('Four colors');

  const SuitColorsSetting(this.label);
  final String label;
}

enum SheetView {
  paper('Paper'),
  cards('Cards');

  const SheetView(this.label);
  final String label;
}

/// The display settings of this device. They are not part of a session.
class DisplayPreferences {
  const DisplayPreferences({
    this.themeMode = ThemeModeSetting.system,
    this.textSize = TextSizeSetting.normal,
    this.suitColors = SuitColorsSetting.two,
    this.sheetView = SheetView.paper,
  });

  final ThemeModeSetting themeMode;
  final TextSizeSetting textSize;
  final SuitColorsSetting suitColors;
  final SheetView sheetView;

  DisplayPreferences copyWith({
    ThemeModeSetting? themeMode,
    TextSizeSetting? textSize,
    SuitColorsSetting? suitColors,
    SheetView? sheetView,
  }) => DisplayPreferences(
    themeMode: themeMode ?? this.themeMode,
    textSize: textSize ?? this.textSize,
    suitColors: suitColors ?? this.suitColors,
    sheetView: sheetView ?? this.sheetView,
  );

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences &&
      other.themeMode == themeMode &&
      other.textSize == textSize &&
      other.suitColors == suitColors &&
      other.sheetView == sheetView;

  @override
  int get hashCode => Object.hash(themeMode, textSize, suitColors, sheetView);

  Map<String, Object?> toJson() => {
    'themeMode': themeMode.name,
    'textSize': textSize.name,
    'suitColors': suitColors.name,
    'sheetView': sheetView.name,
  };

  /// Reads the settings. An unknown or missing value takes its default.
  static DisplayPreferences fromJson(Object? json) {
    final map = json is Map<String, Object?> ? json : const <String, Object?>{};
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return DisplayPreferences(
      themeMode: pick(
        ThemeModeSetting.values,
        map['themeMode'],
        ThemeModeSetting.system,
      ),
      textSize: pick(
        TextSizeSetting.values,
        map['textSize'],
        TextSizeSetting.normal,
      ),
      suitColors: pick(
        SuitColorsSetting.values,
        map['suitColors'],
        SuitColorsSetting.two,
      ),
      sheetView: pick(SheetView.values, map['sheetView'], SheetView.paper),
    );
  }
}
