part of 'feedback.dart';

/// The look of smileyface.dev: ink #141414, cream #FBFAF6, paper #FFFFFF,
/// line #E6E3DA, text #3D3B36 and yellow #FFC93C, with Bricolage Grotesque
/// for headings and Figtree for text. Dark mode follows the dark sections of
/// the website: ink background, cream text and yellow buttons.
FThemeData _smileyfaceTheme(Brightness brightness) {
  const touch = true;
  final colors = brightness == Brightness.light ? _light : _dark;
  final typography = FTypography(
    display: FTypeface.inherit(
      colors: colors,
      touch: touch,
      fontFamily: 'packages/smileyface_feedback/BricolageGrotesque',
    ),
    body: FTypeface.inherit(
      colors: colors,
      touch: touch,
      fontFamily: 'packages/smileyface_feedback/Figtree',
    ),
  );
  return FThemeData(
    colors: colors,
    typography: typography,
    style: FStyle(
      formFieldStyle: .inherit(
        colors: colors,
        typography: typography,
        touch: touch,
      ),
      focusedOutlineStyle: FFocusedOutlineStyle(
        color: colors.primary,
        borderRadius: _radius.md,
      ),
      sizes: FSizes.inherit(touch: touch),
      iconStyle: IconThemeData(
        color: colors.foreground,
        size: typography.body.lg.fontSize,
      ),
      tappableStyle: FTappableStyle(),
      borderRadius: _radius,
      pagePadding: const .symmetric(vertical: 8, horizontal: 20),
    ),
    touch: touch,
  );
}

/// The yellow of smileyface.dev, behind the icon of the intro.
const _accent = Color(0xFFFFC93C);

/// What stands on [_accent].
const _accentForeground = Color(0xFF141414);

const _radius = FBorderRadius(
  xs2: .all(.circular(6)),
  xs: .all(.circular(8)),
  sm: .all(.circular(11)),
  md: .all(.circular(14)),
  lg: .all(.circular(20)),
  xl: .all(.circular(25)),
  xl2: .all(.circular(31)),
  xl3: .all(.circular(36)),
);

final _light = FColors(
  brightness: .light,
  systemOverlayStyle: .dark,
  barrier: const Color(0x33141414),
  background: const Color(0xFFFBFAF6),
  foreground: const Color(0xFF141414),
  primary: const Color(0xFF141414),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFEFECE4),
  secondaryForeground: const Color(0xFF141414),
  muted: const Color(0xFFEFECE4),
  mutedForeground: const Color(0xFF6E6B62),
  destructive: const Color(0xFFD92D20),
  destructiveForeground: const Color(0xFFFFFFFF),
  error: const Color(0xFFD92D20),
  errorForeground: const Color(0xFFFFFFFF),
  card: const Color(0xFFFFFFFF),
  border: const Color(0xFFE6E3DA),
);

final _dark = FColors(
  brightness: .dark,
  systemOverlayStyle: .light,
  barrier: const Color(0x7A000000),
  background: const Color(0xFF141414),
  foreground: const Color(0xFFFBFAF6),
  primary: const Color(0xFFFFC93C),
  primaryForeground: const Color(0xFF141414),
  secondary: const Color(0xFF2A2926),
  secondaryForeground: const Color(0xFFFBFAF6),
  muted: const Color(0xFF2A2926),
  mutedForeground: const Color(0xFFB8B4A8),
  destructive: const Color(0xFFFF6467),
  destructiveForeground: const Color(0xFF141414),
  error: const Color(0xFFFF6467),
  errorForeground: const Color(0xFF141414),
  card: const Color(0xFF1E1D1B),
  border: const Color(0xFF3A3833),
);
