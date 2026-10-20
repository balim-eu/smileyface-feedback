part of 'feedback.dart';

/// What the feedback says, English by default.
class SmileyfaceFeedbackTexts {
  /// The texts, each English unless given.
  const SmileyfaceFeedbackTexts({
    this.title = 'Feedback',
    this.introTitle = 'Shake it',
    this.introBody =
        'Shake your device on any screen to send feedback: tell what '
        'happened and draw on a screenshot. Try it now.',
    this.skip = 'Skip',
    this.hint = 'What happened?',
    this.attachScreenshot = 'Attach the screenshot',
    this.drawOnScreenshot = 'Draw on the screenshot',
    this.dictate = 'Dictate',
    this.stopDictating = 'Stop dictating',
    this.send = 'Send feedback',
    this.listening = 'Listening…',
    this.speechUnavailable = 'Speech recognition is not available.',
    this.failed = "Couldn't send. Check the connection and try again.",
    this.sent = 'Thanks, your feedback was sent.',
    this.close = 'Close',
    this.removeScreenshot = 'Remove the screenshot',
    this.done = 'Done',
    this.draw = 'Draw',
    this.write = 'Write',
    this.undo = 'Undo',
    this.drawHint = 'Draw with your finger',
    this.writeHint = 'Tap where the text goes',
    this.textHint = 'Text on the screenshot',
    this.add = 'Add',
  });

  /// The title of the sheet.
  final String title;

  /// The title of the intro on the first start.
  final String introTitle;

  /// What the intro tells.
  final String introBody;

  /// The button that ends the intro.
  final String skip;

  /// The hint of the message field.
  final String hint;

  /// The button that attaches the screenshot, for screen readers.
  final String attachScreenshot;

  /// The attached screenshot, which opens the editor, for screen readers.
  final String drawOnScreenshot;

  /// The microphone button, for screen readers.
  final String dictate;

  /// The microphone button while it listens, for screen readers.
  final String stopDictating;

  /// The send button, for screen readers.
  final String send;

  /// What the sheet says while it listens.
  final String listening;

  /// What the sheet says when the platform has no speech recognition.
  final String speechUnavailable;

  /// What the sheet says when sending failed.
  final String failed;

  /// What the sheet says once the feedback is sent.
  final String sent;

  /// The close buttons, for screen readers.
  final String close;

  /// The button of the editor that removes the screenshot.
  final String removeScreenshot;

  /// The button of the editor that keeps the drawing.
  final String done;

  /// The drawing tool of the editor.
  final String draw;

  /// The writing tool of the editor.
  final String write;

  /// The button of the editor that undoes the last mark.
  final String undo;

  /// What the editor says while drawing.
  final String drawHint;

  /// What the editor says while writing.
  final String writeHint;

  /// The hint of the field for a text on the screenshot.
  final String textHint;

  /// The button that adds the text to the screenshot.
  final String add;
}
