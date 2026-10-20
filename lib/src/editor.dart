part of 'feedback.dart';

/// Draws lines and writes text on the screenshot: closing keeps the marks it
/// had, Done takes the new ones, the bin removes the screenshot.
class _FeedbackEditor extends HookWidget {
  const _FeedbackEditor({
    required this.screenshot,
    required this.marks,
    required this.config,
    required this.onDone,
    required this.onRemove,
  });

  final _Screenshot screenshot;

  final List<_Mark> marks;

  final SmileyfaceFeedbackConfig config;

  final ValueChanged<List<_Mark>> onDone;

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final current = useState(marks);
    final color = useState(config.markColors.first);
    final writing = useState(false);
    final draft = useState<Offset?>(null);
    final text = useTextEditingController();

    void write() {
      if (draft.value case final position? when text.text.trim().isNotEmpty) {
        current.value = [
          ...current.value,
          _Mark(color.value, [position], text.text.trim()),
        ];
      }
      text.clear();
      draft.value = null;
    }

    final divider = Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colors.border,
    );

    return ColoredBox(
      color: theme.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  FButton.icon(
                    variant: .ghost,
                    semanticsLabel: config.texts.close,
                    onPress: () => onDone(marks),
                    child: const Icon(FLucideIcons.x),
                  ),
                  const Spacer(),
                  FButton.icon(
                    variant: .ghost,
                    semanticsLabel: config.texts.removeScreenshot,
                    onPress: onRemove,
                    child: const Icon(FLucideIcons.trash2),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => onDone(current.value),
                    child: Text(config.texts.done),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: screenshot.size.aspectRatio,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            Offset relative(Offset position) => Offset(
                              position.dx / size.width,
                              position.dy / size.height,
                            );

                            return GestureDetector(
                              onTapUp: writing.value
                                  ? (details) => draft.value = relative(
                                      details.localPosition,
                                    )
                                  : null,
                              onPanStart: writing.value
                                  ? null
                                  : (details) => current.value = [
                                      ...current.value,
                                      _Mark(color.value, [
                                        relative(details.localPosition),
                                      ]),
                                    ],
                              onPanUpdate: writing.value
                                  ? null
                                  : (details) {
                                      final line = current.value.last;
                                      current.value = [
                                        ...current.value.sublist(
                                          0,
                                          current.value.length - 1,
                                        ),
                                        _Mark(line.color, [
                                          ...line.points,
                                          relative(details.localPosition),
                                        ]),
                                      ];
                                    },
                              child: CustomPaint(
                                size: size,
                                painter: _MarksPainter(
                                  screenshot,
                                  current.value,
                                  config,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: draft.value == null
                  ? Text(
                      writing.value
                          ? config.texts.writeHint
                          : config.texts.drawHint,
                      textAlign: TextAlign.center,
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: FTextField(
                            control: .managed(controller: text),
                            hint: config.texts.textHint,
                            autofocus: true,
                            onSubmit: (_) => write(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FButton(
                          mainAxisSize: MainAxisSize.min,
                          onPress: write,
                          child: Text(config.texts.add),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FButton.icon(
                    variant: writing.value ? .ghost : .secondary,
                    semanticsLabel: config.texts.draw,
                    onPress: () => writing.value = false,
                    child: const Icon(FLucideIcons.pencil),
                  ),
                  FButton.icon(
                    variant: writing.value ? .secondary : .ghost,
                    semanticsLabel: config.texts.write,
                    onPress: () => writing.value = true,
                    child: const Icon(FLucideIcons.type),
                  ),
                  divider,
                  for (final value in config.markColors)
                    GestureDetector(
                      onTap: () => color.value = value,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: value == color.value
                                ? theme.colors.foreground
                                : const Color(0x00000000),
                            width: 2,
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: value,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  divider,
                  FButton.icon(
                    variant: .ghost,
                    semanticsLabel: config.texts.undo,
                    onPress: current.value.isEmpty
                        ? null
                        : () => current.value = current.value.sublist(
                            0,
                            current.value.length - 1,
                          ),
                    child: const Icon(FLucideIcons.undo2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line drawn or a text written on the screenshot.
class _Mark {
  const _Mark(this.color, this.points, [this.text]);

  final Color color;

  /// The points of the line, or where the text starts, from 0 to 1 of the
  /// screenshot's width and height.
  final List<Offset> points;

  final String? text;
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.screenshot, this.marks, this.config);

  final _Screenshot screenshot;

  final List<_Mark> marks;

  final SmileyfaceFeedbackConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: screenshot.image,
      fit: BoxFit.fill,
    );
    final scale = size.width / screenshot.size.width;
    for (final mark in marks) {
      final points = [
        for (final point in mark.points)
          Offset(point.dx * size.width, point.dy * size.height),
      ];
      if (mark.text case final text?) {
        TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: mark.color,
                fontSize: config.textSize * scale,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(color: const Color(0xCC000000), blurRadius: 4 * scale),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          )
          ..layout(maxWidth: size.width - points.first.dx)
          ..paint(canvas, points.first)
          ..dispose();
      } else {
        canvas.drawPoints(
          ui.PointMode.polygon,
          points.length == 1 ? [points.first, points.first] : points,
          Paint()
            ..color = mark.color
            ..strokeWidth = config.strokeWidth * scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MarksPainter oldDelegate) =>
      oldDelegate.marks != marks || oldDelegate.screenshot != screenshot;
}

/// The screenshot with its marks as a PNG in the screenshot's resolution.
Future<Uint8List> _png(
  _Screenshot screenshot,
  List<_Mark> marks,
  SmileyfaceFeedbackConfig config,
) async {
  final image = screenshot.image;
  final recorder = ui.PictureRecorder();
  _MarksPainter(screenshot, marks, config).paint(
    Canvas(recorder),
    Size(image.width.toDouble(), image.height.toDouble()),
  );
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(image.width, image.height);
  final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  rendered.dispose();
  return bytes!.buffer.asUint8List();
}
