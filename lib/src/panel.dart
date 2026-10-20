part of 'feedback.dart';

/// The feedback as a sheet at the bottom, in one row: the screenshot, the
/// message, dictation and send. Dragging it down, tapping above it or back
/// closes it.
class _FeedbackPanel extends HookWidget {
  const _FeedbackPanel({
    required this.app,
    required this.url,
    required this.stage,
    required this.database,
    required this.screenshot,
    required this.config,
    required this.onClose,
  });

  final GlobalKey app;

  final String url;

  final String? stage;

  final FutureOr<Object?> Function()? database;

  final _Screenshot screenshot;

  final SmileyfaceFeedbackConfig config;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final message = useTextEditingController();
    final focus = useFocusNode();
    final marks = useState(const <_Mark>[]);
    final attached = useState(false);
    final editing = useState(false);
    final listening = useState(false);
    final unavailable = useState(false);
    final status = useState(_Status.ready);
    final height = useRef<double>(0);
    final slide = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final offset = useMemoized(
      () => slide.drive(
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
      ),
      [slide],
    );
    useListenable(message);
    useEffect(() {
      unawaited(slide.animateTo(1, curve: Curves.easeOutCubic));
      return null;
    }, [slide]);

    Future<void> dismiss() async {
      if (slide.status == AnimationStatus.reverse) return;
      focus.unfocus();
      await slide.animateBack(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInCubic,
      );
      onClose();
    }

    Future<void> send() async {
      focus.unfocus();
      status.value = _Status.sending;
      try {
        await _send(
          url: url,
          app: app,
          stage: stage,
          database: database,
          message: message.text.trim(),
          screenshot: attached.value
              ? await _png(screenshot, marks.value, config)
              : null,
        );
      } on Object catch (error, stackTrace) {
        _logger.warning('Feedback was not sent', error, stackTrace);
        if (context.mounted) status.value = _Status.failed;
        return;
      }
      if (!context.mounted) return;
      status.value = _Status.sent;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (context.mounted) await dismiss();
    }

    _useBackButton(
      open: true,
      onBack: () {
        if (editing.value) {
          editing.value = false;
        } else {
          unawaited(dismiss());
        }
      },
    );

    if (editing.value) {
      return _FeedbackEditor(
        screenshot: screenshot,
        marks: marks.value,
        config: config,
        onDone: (value) {
          marks.value = value;
          editing.value = false;
        },
        onRemove: () {
          attached.value = false;
          marks.value = const [];
          editing.value = false;
        },
      );
    }

    final sending = status.value == _Status.sending;
    final canSend =
        !sending &&
        !listening.value &&
        (attached.value || message.text.trim().isNotEmpty);
    final texts = config.texts;
    final note = switch (status.value) {
      _Status.failed => (texts.failed, theme.colors.error),
      _ when listening.value => (texts.listening, theme.colors.mutedForeground),
      _ when unavailable.value => (
        texts.speechUnavailable,
        theme.colors.mutedForeground,
      ),
      _ => null,
    };
    final bottom = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The first tap closes the keyboard, the next one the sheet.
            onTap: () =>
                focus.hasFocus ? focus.unfocus() : unawaited(dismiss()),
            child: FadeTransition(
              opacity: slide,
              child: ColoredBox(color: theme.colors.barrier),
            ),
          ),
        ),
        // One pixel beyond the screen, so only the top border shows.
        Positioned(
          left: -1,
          right: -1,
          bottom: -1,
          child: SlideTransition(
            position: offset,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: config.panelWidth),
                child: Builder(
                  builder: (context) => GestureDetector(
                    onVerticalDragStart: (_) =>
                        height.value = context.size?.height ?? 0,
                    onVerticalDragUpdate: (details) {
                      if (height.value <= 0) return;
                      slide.value -= (details.primaryDelta ?? 0) / height.value;
                    },
                    onVerticalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) > 700 ||
                          slide.value < 0.7) {
                        unawaited(dismiss());
                      } else {
                        unawaited(
                          slide.animateTo(1, curve: Curves.easeOutCubic),
                        );
                      }
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colors.background,
                        border: Border.all(color: theme.colors.border),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 24,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(13, 8, 13, 13 + bottom),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.colors.mutedForeground
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (note case (final text, final color)) ...[
                              Text(
                                text,
                                style: theme.typography.body.xs.copyWith(
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (status.value == _Status.sent)
                              _Sent(text: texts.sent)
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _ScreenshotButton(
                                    screenshot: screenshot,
                                    marks: marks.value,
                                    config: config,
                                    attached: attached.value,
                                    texts: texts,
                                    onPress: sending
                                        ? null
                                        : () {
                                            if (!attached.value) {
                                              attached.value = true;
                                              return;
                                            }
                                            // The editor ends the dictation.
                                            listening.value = false;
                                            editing.value = true;
                                          },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FTextField(
                                      control: .managed(controller: message),
                                      focusNode: focus,
                                      hint: texts.hint,
                                      textCapitalization: .sentences,
                                      minLines: 1,
                                      maxLines: 4,
                                      enabled: !sending,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _Dictation(
                                    message: message,
                                    listening: listening,
                                    unavailable: unavailable,
                                    enabled: !sending,
                                    texts: texts,
                                  ),
                                  const SizedBox(width: 8),
                                  FButton.icon(
                                    variant: .primary,
                                    semanticsLabel: texts.send,
                                    onPress: canSend
                                        ? () => unawaited(send())
                                        : null,
                                    child: sending
                                        ? const FCircularProgress()
                                        : const Icon(FLucideIcons.arrowUp),
                                  ),
                                ],
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
        ),
      ],
    );
  }
}

enum _Status { ready, sending, sent, failed }

/// Attaches the screenshot, or shows the attached one, which a tap opens for
/// drawing and writing.
class _ScreenshotButton extends HookWidget {
  const _ScreenshotButton({
    required this.screenshot,
    required this.marks,
    required this.config,
    required this.attached,
    required this.texts,
    required this.onPress,
  });

  final _Screenshot screenshot;

  final List<_Mark> marks;

  final SmileyfaceFeedbackConfig config;

  final bool attached;

  final SmileyfaceFeedbackTexts texts;

  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    if (!attached) {
      return FButton.icon(
        semanticsLabel: texts.attachScreenshot,
        onPress: onPress,
        child: const Icon(FLucideIcons.imagePlus),
      );
    }

    return FButton.raw(
      variant: .outline,
      semanticsLabel: texts.drawOnScreenshot,
      onPress: onPress,
      child: SizedBox.square(
        dimension: 44,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: CustomPaint(
                size: screenshot.size,
                painter: _MarksPainter(screenshot, marks, config),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sent extends HookWidget {
  const _Sent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FLucideIcons.circleCheck, size: 20, color: theme.colors.primary),
          const SizedBox(width: 8),
          // Long translations wrap instead of overflowing.
          Flexible(
            child: Text(
              text,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
