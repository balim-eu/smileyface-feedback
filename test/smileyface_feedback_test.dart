import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:smileyface_feedback/smileyface_feedback.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

class _Paths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _Paths(this.support);

  final String support;

  @override
  Future<String?> getApplicationSupportPath() async => support;
}

class _Speech extends Fake
    with MockPlatformInterfaceMixin
    implements SpeechToTextPlatform {
  @override
  void Function(String results)? onTextRecognition;

  @override
  void Function(String error)? onError;

  @override
  void Function(String status)? onStatus;

  @override
  void Function(double level)? onSoundLevel;

  @override
  Future<bool> initialize({
    // The platform interface leaves it untyped.
    // ignore: type_annotate_public_apis
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async => true;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<List<dynamic>> locales() async => [];

  @override
  Future<bool> listen({
    String? localeId,
    // The platform interface leaves them untyped.
    // ignore: type_annotate_public_apis
    partialResults = true,
    // The platform interface leaves it untyped.
    // ignore: type_annotate_public_apis
    onDevice = false,
    int listenMode = 0,
    // The platform interface leaves it untyped.
    // ignore: type_annotate_public_apis
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    onStatus?.call('listening');
    return true;
  }

  @override
  Future<void> stop() async => onStatus?.call('notListening');

  @override
  Future<void> cancel() async => onStatus?.call('notListening');
}

final Finder _send = find.byIcon(FLucideIcons.arrowUp);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory support;
  late File marker;
  MockStreamHandlerEventSink? sensor;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Shop',
      packageName: 'com.example.shop',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  setUp(() {
    HttpOverrides.global = null;
    support = Directory.systemTemp.createTempSync('smileyface_feedback');
    marker = File('${support.path}/feedback/intro_seen');
    PathProviderPlatform.instance = _Paths(support.path);
    SpeechToTextPlatform.instance = _Speech();
    sensor = null;
    messenger
      ..setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
        (_) async => null,
      )
      ..setMockStreamHandler(
        const EventChannel('dev.fluttercommunity.plus/sensors/accelerometer'),
        MockStreamHandler.inline(
          onListen: (_, events) {
            sensor = events;
          },
        ),
      );
  });

  tearDown(() => support.deleteSync(recursive: true));

  /// Lets real async work, like decoding images or HTTP, run until [done].
  Future<void> settle(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 40 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Animations take a frame to start: one more after them.
  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  Future<void> start(
    WidgetTester tester, {
    String url = 'http://127.0.0.1:1/feedback',
    Widget child = const ColoredBox(color: Color(0xFF00FF00)),
  }) async {
    // Widget tests run as Android, which can be shaken.
    await tester.pumpWidget(
      SmileyfaceFeedback(
        url: url,
        stage: 'staging',
        database: () => {
          'cart': {'items': 2},
        },
        child: child,
      ),
    );
    await tester.pump();
  }

  Future<void> intro(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> shake(WidgetTester tester) async {
    // ShakeDetector ignores shakes in the first 500 ms of real time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    sensor!.success(<double>[40, 40, 40, 0]);
    await settle(tester, () => _send.evaluate().isNotEmpty);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> open(WidgetTester tester, {String? url}) async {
    marker.createSync(recursive: true);
    if (url == null) {
      await start(tester);
    } else {
      await start(tester, url: url);
    }
    await tester.pump(const Duration(seconds: 2));
    await shake(tester);
    expect(_send, findsOneWidget);
  }

  FButton button(WidgetTester tester, Finder icon) => tester.widget<FButton>(
    find.ancestor(of: icon, matching: find.byType(FButton)).first,
  );

  group('intro', () {
    testWidgets('shows after a second and Skip ends it for good', (
      tester,
    ) async {
      await start(tester);
      expect(find.text('Shake it'), findsNothing);
      await intro(tester);
      expect(find.text('Shake it'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Shake it'), findsNothing);
      expect(marker.existsSync(), isTrue);
    });

    testWidgets('shows no more once seen', (tester) async {
      marker.createSync(recursive: true);
      await start(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Shake it'), findsNothing);
    });

    testWidgets('blocks taps on the app until it ends', (tester) async {
      var tapped = false;
      await start(
        tester,
        child: GestureDetector(
          onTap: () => tapped = true,
          child: const ColoredBox(color: Color(0xFF00FF00)),
        ),
      );
      await intro(tester);
      await tester.tapAt(const Offset(5, 5));
      expect(tapped, isFalse);
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tapAt(const Offset(5, 5));
      expect(tapped, isTrue);
    });

    testWidgets('a shake ends it and opens the feedback', (tester) async {
      await start(tester);
      await intro(tester);
      await shake(tester);
      expect(find.text('Shake it'), findsNothing);
      expect(marker.existsSync(), isTrue);
      expect(_send, findsOneWidget);
    });

    testWidgets('back ends it', (tester) async {
      await start(tester);
      await intro(tester);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Shake it'), findsNothing);
      expect(marker.existsSync(), isTrue);
    });

    testWidgets("the texts are the config's", (tester) async {
      await tester.pumpWidget(
        const SmileyfaceFeedback(
          url: 'http://127.0.0.1:1/feedback',
          config: SmileyfaceFeedbackConfig(
            texts: SmileyfaceFeedbackTexts(introTitle: 'Schüttel es'),
          ),
          child: SizedBox(),
        ),
      );
      await intro(tester);
      expect(find.text('Schüttel es'), findsOneWidget);
    });
  });

  group('sheet', () {
    testWidgets('attaches the screenshot, which the editor removes', (
      tester,
    ) async {
      await open(tester);
      expect(button(tester, _send).onPress, isNull, reason: 'nothing to send');
      await tester.tap(find.byIcon(FLucideIcons.imagePlus));
      await tester.pump();
      expect(find.byIcon(FLucideIcons.imagePlus), findsNothing);
      expect(button(tester, _send).onPress, isNotNull);
      await tester.tap(find.bySemanticsLabel('Draw on the screenshot'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Remove the screenshot'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Done'), findsNothing);
      expect(find.byIcon(FLucideIcons.imagePlus), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('dictates', (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(FLucideIcons.mic));
      await settle(tester, () => find.text('Listening…').evaluate().isNotEmpty);
      expect(find.text('Listening…'), findsOneWidget);
      expect(button(tester, _send).onPress, isNull, reason: 'while listening');
      await tester.tap(find.byIcon(FLucideIcons.square));
      await settle(tester, () => find.text('Listening…').evaluate().isEmpty);
      expect(find.byIcon(FLucideIcons.mic), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    for (final ok in [true, false]) {
      testWidgets(ok ? 'sends and closes' : 'says when sending failed', (
        tester,
      ) async {
        final server = (await tester.runAsync(
          () => HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        ))!;
        final bodies = <String>[];
        final types = <String?>[];
        server.listen((request) async {
          types.add(request.headers.contentType?.mimeType);
          bodies.add(await latin1.decoder.bind(request).join());
          request.response.statusCode = ok ? 201 : 500;
          await request.response.close();
        });
        addTearDown(() => tester.runAsync(server.close));
        await open(tester, url: 'http://127.0.0.1:${server.port}/feedback');
        await tester.tap(find.byIcon(FLucideIcons.imagePlus));
        await tester.enterText(
          find.byType(EditableText),
          'Pay twice breaks checkout',
        );
        await tester.pump();
        await tester.tap(_send);
        await tester.pump();
        final result = ok
            ? find.text('Thanks, your feedback was sent.')
            : find.textContaining("Couldn't send");
        await settle(tester, () => result.evaluate().isNotEmpty);
        expect(result, findsOneWidget);
        expect(types.single, 'multipart/form-data');
        final body = bodies.single;
        for (final part in [
          'name="message"',
          'Pay twice breaks checkout',
          'name="report"; filename="report.json"',
          'name="widget_tree"; filename="widget_tree.txt"',
          'name="screenshot"; filename="screenshot.png"',
        ]) {
          expect(body, contains(part));
        }
        final report = jsonDecode(
          RegExp(
            r'filename="report.json"\r\n(?:[^\r\n]+\r\n)*\r\n(.*?)\r\n--',
            dotAll: true,
          ).firstMatch(body)![1]!,
        ) as Map<String, dynamic>;
        expect(report['app'], {
          'packageName': 'com.example.shop',
          'version': '1.0.0',
          'buildNumber': '7',
          'stage': 'staging',
        });
        expect(report['device'], containsPair('platform', 'android'));
        expect(report['database'], {
          'cart': {'items': 2},
        });
        expect(report, contains('blocs'));
        if (ok) {
          await tester.pump(const Duration(milliseconds: 1500));
          await frames(tester);
          expect(_send, findsNothing);
        } else {
          expect(button(tester, _send).onPress, isNotNull, reason: 'retry');
        }
        await tester.pump(const Duration(seconds: 4));
      });
    }

    testWidgets('a drag down closes it, a short one springs back', (
      tester,
    ) async {
      await open(tester);
      final handle = tester.getTopLeft(_send) - const Offset(0, 16);
      await tester.timedDragFrom(
        handle,
        const Offset(0, 20),
        const Duration(milliseconds: 600),
      );
      await frames(tester);
      expect(_send, findsOneWidget);
      await tester.timedDragFrom(
        handle,
        const Offset(0, 200),
        const Duration(milliseconds: 800),
      );
      await frames(tester);
      expect(_send, findsNothing);
    });

    testWidgets('a tap above closes the keyboard first, then the sheet', (
      tester,
    ) async {
      await open(tester);
      await tester.showKeyboard(find.byType(EditableText));
      await tester.pump();
      await tester.tapAt(const Offset(200, 100));
      await frames(tester);
      expect(_send, findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tapAt(const Offset(200, 100));
      await frames(tester);
      expect(_send, findsNothing);
    });

    testWidgets('back closes the editor first, then the sheet', (tester) async {
      await open(tester);
      await tester.tap(find.byIcon(FLucideIcons.imagePlus));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Draw on the screenshot'));
      await tester.pump();
      expect(find.text('Done'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Done'), findsNothing);
      expect(_send, findsOneWidget);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(_send, findsNothing);
    });
  });

  test('isSupported on Android and iOS only', () {
    for (final (platform, supported) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, true),
      (TargetPlatform.macOS, false),
      (TargetPlatform.windows, false),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(SmileyfaceFeedback.isSupported, supported, reason: '$platform');
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
