/// The feedback of staging builds: testers shake the device and send a
/// message, typed or dictated, and an annotated screenshot together with the
/// state of the app to a URL.
library;

export 'src/feedback.dart'
    show
        SmileyfaceFeedback,
        SmileyfaceFeedbackBlocObserver,
        SmileyfaceFeedbackConfig,
        SmileyfaceFeedbackTexts;
