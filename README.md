# smileyface_feedback

The feedback of staging builds: testers shake the device and send a message, typed or dictated, and an annotated screenshot together with the state of the app to a URL.

- **Shake to open**, on Android and iOS. The first start shows a "Shake it" intro, which a shake or Skip ends for good.
- **A sheet at the bottom** like the form sheets and the chat composer of the smileyface app: the screenshot as a pending attachment, drawn and written on in an editor, and one row with the attach button, the message, a microphone that dictates it and send.
- **The look of smileyface.dev**, apart from the app's theme: ink, cream and yellow, Bricolage Grotesque and Figtree, which the package brings with their licenses.
- **The state of the app** goes with it: app and device, the open blocs with their recent events and errors, the widgets on the screen and, if the app gives it, its local data.

## Setup

```yaml
dependencies:
  smileyface_feedback:
    git:
      url: https://github.com/balim-eu/smileyface-feedback
```

Wrap the app where testers use it, e.g. in staging builds, and observe its blocs for the report:

```dart
import 'package:smileyface_feedback/smileyface_feedback.dart';

final feedback =
    Stage.current == Stage.staging &&
    Env.feedbackUrl.isNotEmpty &&
    SmileyfaceFeedback.isSupported;

Bloc.observer = MultiBlocObserver(
  observers: [if (feedback) SmileyfaceFeedbackBlocObserver.instance],
);

runApp(
  feedback
      ? SmileyfaceFeedback(
          url: Env.feedbackUrl,
          stage: Stage.current.name,
          database: () => sembast.Store.dump(),
          child: app,
        )
      : app,
);
```

`SmileyfaceFeedbackConfig` changes the look, e.g. `lightTheme` and `darkTheme` for other forui themes, and `SmileyfaceFeedbackTexts` what it says, e.g. in German:

```dart
SmileyfaceFeedback(
  url: Env.feedbackUrl,
  config: const SmileyfaceFeedbackConfig(
    texts: SmileyfaceFeedbackTexts(introTitle: 'Schüttel es', hint: 'Was ist passiert?'),
  ),
  child: app,
)
```

Dictation needs the microphone and speech recognition. iOS, in `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Listens to spoken feedback in test builds.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Turns spoken feedback into text in test builds.</string>
```

Android, e.g. in `android/app/src/staging/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

## What the URL receives

One `POST` to the URL as it is, query included, as `multipart/form-data`:

| Part | Content |
|------|---------|
| `message` | the typed or dictated text, may be empty |
| `report` | `report.json`: `createdAt`, `app` (`packageName`, `version`, `buildNumber`, `stage`), `device` (`platform`, `osVersion`, `locale`, `size`, `pixelRatio`, `textScale`, `brightness`), `blocs` (`open` with their state, `history` of the last 50 events and errors) and `database`, null without one |
| `widget_tree` | `widget_tree.txt`: the widgets on the screen, one chain per line |
| `screenshot` | `screenshot.png` with the drawing and text, when the tester attached it |

Any 2xx is sent; anything else, redirects too, shows that sending failed, and the tester can send again. There is no auth header: put a secret into the URL, e.g. `?token=…`. On the web, answer with `Access-Control-Allow-Origin`.
