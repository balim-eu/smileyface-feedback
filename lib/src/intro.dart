part of 'feedback.dart';

/// Tells testers on the first start that shaking the device opens the
/// feedback, on a card with the yellow of smileyface.dev. Shaking opens it
/// and ends the intro, Skip ends it without.
class _FeedbackIntro extends HookWidget {
  const _FeedbackIntro({required this.config, required this.onSkip});

  final SmileyfaceFeedbackConfig config;

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final wiggle = useAnimationController(
      duration: const Duration(milliseconds: 1600),
    );
    useEffect(() {
      unawaited(wiggle.repeat());
      return null;
    }, [wiggle]);

    final colors = theme.colors;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: colors.barrier)),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.95 + 0.05 * value,
                    child: child,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colors.card,
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: colors.border),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: wiggle,
                                builder: (context, child) => Transform.rotate(
                                  angle: _wiggle(wiggle.value),
                                  child: child,
                                ),
                                child: const Icon(
                                  FLucideIcons.vibrate,
                                  size: 30,
                                  color: _accentForeground,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            config.texts.introTitle,
                            textAlign: TextAlign.center,
                            style: theme.typography.display.xl2.copyWith(
                              color: colors.foreground,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            config.texts.introBody,
                            textAlign: TextAlign.center,
                            style: theme.typography.body.md.copyWith(
                              color: colors.mutedForeground,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FButton(
                            variant: .secondary,
                            onPress: onSkip,
                            child: Text(config.texts.skip),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The angle of the icon at [progress] of a round: a shake that fades out,
/// then a rest.
double _wiggle(double progress) {
  const shaking = 0.4;
  if (progress >= shaking) return 0;
  final t = progress / shaking;
  return 0.3 * (1 - t) * math.sin(t * 4 * 2 * math.pi);
}

/// Whether the intro is still to show: until the tester shakes the device or
/// skips it once. The first start waits a moment, so the intro comes after
/// the app's first screen.
Future<bool> _introPending() async {
  try {
    if ((await _introSeenFile()).existsSync()) return false;
  } on Object catch (error, stackTrace) {
    _logger.warning('Feedback intro state unreadable', error, stackTrace);
    return false;
  }
  await Future<void>.delayed(const Duration(seconds: 1));
  return true;
}

/// Remembers that the intro was shown, in the app's support directory.
Future<void> _introSeen() async {
  try {
    (await _introSeenFile()).createSync(recursive: true);
  } on Object catch (error, stackTrace) {
    _logger.warning('Feedback intro state not saved', error, stackTrace);
  }
}

Future<File> _introSeenFile() async {
  final directory = await getApplicationSupportDirectory();
  final separator = Platform.pathSeparator;
  return File('${directory.path}${separator}feedback${separator}intro_seen');
}
