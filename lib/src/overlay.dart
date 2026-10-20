part of 'feedback.dart';

/// Lets testers send feedback from any screen of [child].
///
/// Shaking the device takes a screenshot of [child] and opens a sheet at the
/// bottom for a message, typed or dictated, and the screenshot to draw and
/// write on. Send posts them with the state of the app to [url] as
/// multipart/form-data: `message`, `report` (report.json), `widget_tree`
/// (widget_tree.txt) and `screenshot` (screenshot.png) when attached. The
/// first start shows an intro that asks to shake.
///
/// Wrap the app with it where testers use it, e.g. in staging builds, and
/// only when [isSupported]:
///
/// ```dart
/// runApp(
///   Stage.current == Stage.staging && SmileyfaceFeedback.isSupported
///       ? SmileyfaceFeedback(url: Env.feedbackUrl, child: app)
///       : app,
/// );
/// ```
class SmileyfaceFeedback extends HookWidget {
  /// The feedback around [child], sent to [url].
  const SmileyfaceFeedback({
    required this.url,
    required this.child,
    this.stage,
    this.database,
    this.config = const SmileyfaceFeedbackConfig(),
    super.key,
  });

  /// Whether the device can be shaken, which opens the feedback: on Android
  /// and iOS.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Where the feedback goes.
  final String url;

  /// The app.
  final Widget child;

  /// The stage of the app in the report, e.g. staging.
  final String? stage;

  /// The local data of the app in the report, e.g. a dump of its database.
  final FutureOr<Object?> Function()? database;

  /// How the feedback looks and what it says.
  final SmileyfaceFeedbackConfig config;

  @override
  Widget build(BuildContext context) {
    final app = useMemoized(GlobalKey.new);
    final screenshot = useState<_Screenshot?>(null);
    final intro = useState(false);
    final capturing = useRef(false);
    useEffect(() => screenshot.value?.image.dispose, [screenshot.value]);
    useEffect(() {
      unawaited(
        _introPending().then((pending) {
          if (context.mounted) intro.value = pending;
        }),
      );
      return null;
    }, const []);

    Future<void> open() async {
      if (capturing.value || screenshot.value != null) return;
      capturing.value = true;
      try {
        final captured = await _capture(app);
        if (!context.mounted) return;
        screenshot.value = captured;
      } finally {
        capturing.value = false;
      }
    }

    void close() => screenshot.value = null;

    void endIntro() {
      intro.value = false;
      unawaited(_introSeen());
    }

    _useShake(() {
      if (intro.value) endIntro();
      unawaited(open());
    });
    // The panel handles back itself, to close with its animation.
    _useBackButton(open: intro.value, onBack: endIntro);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(key: app, child: child),
          FTheme(
            data: config.theme(MediaQuery.platformBrightnessOf(context)),
            // Each overlay has its own key: an Overlay takes its entries only
            // when it is created.
            child: switch (screenshot.value) {
              null when intro.value => Overlay(
                key: const ValueKey('intro'),
                initialEntries: [
                  OverlayEntry(
                    builder: (context) =>
                        _FeedbackIntro(config: config, onSkip: endIntro),
                  ),
                ],
              ),
              null => const SizedBox.shrink(),
              final screenshot => Overlay(
                key: ObjectKey(screenshot),
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => _FeedbackPanel(
                      app: app,
                      url: url,
                      stage: stage,
                      database: database,
                      screenshot: screenshot,
                      config: config,
                      onClose: close,
                    ),
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _BackButtonObserver with WidgetsBindingObserver {
  _BackButtonObserver(this.onBack);

  final VoidCallback onBack;

  @override
  Future<bool> didPopRoute() async {
    onBack();
    return true;
  }
}

/// A screenshot of the app and the logical size of the screen it shows.
class _Screenshot {
  const _Screenshot(this.image, this.size);

  final ui.Image image;

  final Size size;
}

Future<_Screenshot?> _capture(GlobalKey app) async {
  final context = app.currentContext;
  final boundary = context?.findRenderObject();
  if (context == null || boundary is! RenderRepaintBoundary) return null;
  final pixelRatio = MediaQuery.devicePixelRatioOf(context);
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  // A copy: layout rejects the size of a render object in another one's.
  return _Screenshot(image, Size.copy(boundary.size));
}

/// Calls [onBack] on the back button instead of popping the app's route.
void _useBackButton({required bool open, required VoidCallback onBack}) {
  useEffect(() {
    if (!open) return null;
    final observer = _BackButtonObserver(onBack);
    WidgetsBinding.instance.addObserver(observer);
    return () => WidgetsBinding.instance.removeObserver(observer);
  }, [open]);
}

/// Calls [onShake] when the tester shakes the device.
void _useShake(VoidCallback onShake) {
  useEffect(() {
    if (!SmileyfaceFeedback.isSupported) return null;
    final detector = ShakeDetector.autoStart(onPhoneShake: (_) => onShake());
    return detector.stopListening;
  }, const []);
}
