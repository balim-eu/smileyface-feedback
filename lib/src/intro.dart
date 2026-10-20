part of 'feedback.dart';

/// Tells testers on the first start that shaking the device opens the
/// feedback. Shaking opens it and ends the intro, Skip ends it without.
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

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: theme.colors.barrier)),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                  constraints: BoxConstraints(maxWidth: config.panelWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colors.background,
                      border: Border.all(color: theme.colors.border),
                      borderRadius: theme.style.borderRadius.lg,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: wiggle,
                            builder: (context, child) => Transform.rotate(
                              angle: _wiggle(wiggle.value),
                              child: child,
                            ),
                            child: Icon(
                              FLucideIcons.vibrate,
                              size: 40,
                              color: theme.colors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            config.texts.introTitle,
                            textAlign: TextAlign.center,
                            style: theme.typography.body.xl.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            config.texts.introBody,
                            textAlign: TextAlign.center,
                            style: theme.typography.body.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FButton(
                            variant: .outline,
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
