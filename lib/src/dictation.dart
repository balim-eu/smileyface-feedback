part of 'feedback.dart';

/// The microphone button: turns what the tester says into text at the end of
/// [message]. Ghost while it waits, like the attach button, red with a stop
/// sign while it listens.
class _Dictation extends HookWidget {
  const _Dictation({
    required this.message,
    required this.listening,
    required this.unavailable,
    required this.enabled,
    required this.texts,
  });

  final TextEditingController message;

  final ValueNotifier<bool> listening;

  /// Whether the platform has no speech recognition, found on the first tap.
  final ValueNotifier<bool> unavailable;

  final bool enabled;

  final SmileyfaceFeedbackTexts texts;

  @override
  Widget build(BuildContext context) {
    // One instance per app, which takes its listeners only on the first
    // initialize: each panel sets and removes them itself.
    final speech = useMemoized(SpeechToText.new);
    useEffect(
      () => () {
        speech
          ..statusListener = null
          ..errorListener = null;
        unawaited(speech.cancel());
      },
      [speech],
    );

    Future<void> start() async {
      try {
        unavailable.value = !(speech.isAvailable || await speech.initialize());
      } on Object {
        unavailable.value = true;
      }
      if (unavailable.value) return;
      speech
        ..statusListener = ((status) =>
            listening.value = status == SpeechToText.listeningStatus)
        ..errorListener = ((_) => listening.value = false);
      final before = message.text.trimRight();
      await speech.listen(
        onResult: (result) {
          final text = [
            if (before.isNotEmpty) before,
            result.recognizedWords,
          ].join(' ');
          message.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    }

    return FButton.icon(
      variant: listening.value ? .destructive : .ghost,
      semanticsLabel: listening.value ? texts.stopDictating : texts.dictate,
      onPress: !enabled
          ? null
          : listening.value
          ? speech.stop
          : start,
      child: Icon(listening.value ? FLucideIcons.square : FLucideIcons.mic),
    );
  }
}
