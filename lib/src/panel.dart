part of 'feedback.dart';

/// The feedback as a sheet at the bottom, like the form sheets and the
/// composer of the smileyface app: a grabber and a header, the screenshot as
/// a pending attachment, and one row with the attach button, the message,
/// dictation and send. Dragging it down, tapping above it or back closes it.
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
      unawaited(HapticFeedback.lightImpact());
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
    final colors = theme.colors;
    final bottom = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    void edit() {
      // The editor ends the dictation.
      listening.value = false;
      editing.value = true;
    }

    void remove() {
      attached.value = false;
      marks.value = const [];
    }

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
              child: ColoredBox(color: colors.barrier),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
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
                        color: colors.background,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottom),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: colors.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      texts.title,
                                      style: theme.typography.body.lg.copyWith(
                                        color: colors.foreground,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  FButton.icon(
                                    variant: .ghost,
                                    semanticsLabel: texts.close,
                                    onPress: () => unawaited(dismiss()),
                                    child: const Icon(FLucideIcons.x),
                                  ),
                                ],
                              ),
                            ),
                            if (attached.value && status.value != _Status.sent)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _Attachment(
                                    screenshot: screenshot,
                                    marks: marks.value,
                                    config: config,
                                    onEdit: sending ? null : edit,
                                    onRemove: sending ? null : remove,
                                  ),
                                ),
                              ),
                            if (note case (final text, final color))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  0,
                                ),
                                child: Text(
                                  text,
                                  style: theme.typography.body.xs.copyWith(
                                    color: color,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            // The composer is part of its field: a tap on its
                            // buttons keeps the keyboard up.
                            TextFieldTapRegion(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: colors.border),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: status.value == _Status.sent
                                      ? _Sent(text: texts.sent)
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            FButton.icon(
                                              variant: .ghost,
                                              semanticsLabel: attached.value
                                                  ? texts.drawOnScreenshot
                                                  : texts.attachScreenshot,
                                              onPress: sending
                                                  ? null
                                                  : attached.value
                                                  ? edit
                                                  : () => attached.value = true,
                                              child: const Icon(
                                                FLucideIcons.imagePlus,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: FTextField.multiline(
                                                control: .managed(
                                                  controller: message,
                                                ),
                                                focusNode: focus,
                                                hint: texts.hint,
                                                minLines: 1,
                                                maxLines: 5,
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
                                            const SizedBox(width: 4),
                                            FButton.icon(
                                              variant: .secondary,
                                              semanticsLabel: texts.send,
                                              onPress: canSend
                                                  ? () => unawaited(send())
                                                  : null,
                                              child: sending
                                                  ? const FCircularProgress()
                                                  : const Icon(
                                                      FLucideIcons.arrowUp,
                                                    ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
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

/// The attached screenshot, like a pending file of the chat: a tap opens it
/// for drawing and writing, the badge removes it.
class _Attachment extends HookWidget {
  const _Attachment({
    required this.screenshot,
    required this.marks,
    required this.config,
    required this.onEdit,
    required this.onRemove,
  });

  final _Screenshot screenshot;

  final List<_Mark> marks;

  final SmileyfaceFeedbackConfig config;

  final VoidCallback? onEdit;

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          button: true,
          label: config.texts.drawOnScreenshot,
          child: GestureDetector(
            onTap: onEdit,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: colors.muted,
                child: SizedBox.square(
                  dimension: 68,
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
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Semantics(
            button: true,
            label: config.texts.removeScreenshot,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.foreground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FLucideIcons.x,
                  size: 14,
                  color: colors.background,
                ),
              ),
            ),
          ),
        ),
      ],
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
