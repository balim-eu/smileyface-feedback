part of 'feedback.dart';

/// How the feedback looks and what it says, apart from the app's theme:
/// restyling the app leaves the feedback alone and the other way around.
class SmileyfaceFeedbackConfig {
  /// The feedback with [lightTheme] and [darkTheme], the look of
  /// smileyface.dev by default, and [texts], English by default.
  const SmileyfaceFeedbackConfig({
    this.lightTheme,
    this.darkTheme,
    this.texts = const SmileyfaceFeedbackTexts(),
    this.panelWidth = 480,
    this.markColors = const [
      Color(0xFFEF4444),
      Color(0xFFFACC15),
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
    ],
    this.strokeWidth = 4,
    this.textSize = 18,
  });

  /// The forui theme in light mode, the light look of smileyface.dev when
  /// null.
  final FThemeData? lightTheme;

  /// The forui theme in dark mode, the dark look of smileyface.dev when null.
  final FThemeData? darkTheme;

  /// What the feedback says.
  final SmileyfaceFeedbackTexts texts;

  /// The maximum width of the sheet, which tablets leave room beside.
  final double panelWidth;

  /// The colors to draw and write on the screenshot with, the first by
  /// default.
  final List<Color> markColors;

  /// The width of lines on the screenshot, in logical pixels of the screen.
  final double strokeWidth;

  /// The size of text on the screenshot, in logical pixels of the screen.
  final double textSize;

  /// The theme of the feedback in [brightness].
  FThemeData theme(Brightness brightness) => switch (brightness) {
    Brightness.light => lightTheme ?? _smileyfaceTheme(brightness),
    Brightness.dark => darkTheme ?? _smileyfaceTheme(brightness),
  };
}
