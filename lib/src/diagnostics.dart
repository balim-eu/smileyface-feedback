part of 'feedback.dart';

/// Remembers the open blocs and their recent events and errors for the
/// report of the feedback, in release builds too. Add [instance] to the
/// observers of the app where it uses [SmileyfaceFeedback].
class SmileyfaceFeedbackBlocObserver extends BlocObserver {
  SmileyfaceFeedbackBlocObserver._();

  /// The observer of the app.
  static final instance = SmileyfaceFeedbackBlocObserver._();

  static const _limit = 50;

  final _blocs = <BlocBase<dynamic>>{};

  final _history = <Map<String, Object?>>[];

  /// The open blocs with their states and the last 50 events and errors.
  Map<String, Object?> toJson() => {
    'open': [
      for (final bloc in _blocs)
        {'bloc': '${bloc.runtimeType}', 'state': '${bloc.state}'},
    ],
    'history': _history,
  };

  @override
  void onClose(BlocBase<dynamic> bloc) {
    _blocs.remove(bloc);
    super.onClose(bloc);
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _blocs.add(bloc);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _remember(bloc, {'error': '$error', 'stackTrace': '$stackTrace'});
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _remember(bloc, {'event': '$event'});
  }

  void _remember(BlocBase<dynamic> bloc, Map<String, Object?> entry) {
    _history.add({
      'time': DateTime.now().toUtc().toIso8601String(),
      'bloc': '${bloc.runtimeType}',
      ...entry,
    });
    if (_history.length > _limit) _history.removeAt(0);
  }
}

/// Posts the feedback as multipart/form-data to [url]:
///
/// - `message`: what the tester wrote or dictated, maybe empty
/// - `report`: report.json with the app, the device, the blocs and the database
/// - `widget_tree`: widget_tree.txt, the widgets on the screen
/// - `screenshot`: screenshot.png with the drawing and text, when attached
Future<void> _send({
  required String url,
  required GlobalKey app,
  required String message,
  required Uint8List? screenshot,
  required String? stage,
  required FutureOr<Object?> Function()? database,
}) async {
  final report = await _report(app, stage: stage, database: database);
  final request = http.MultipartRequest('POST', Uri.parse(url))
    ..fields['message'] = message
    ..files.add(
      http.MultipartFile.fromString(
        'report',
        jsonEncode(report, toEncodable: (value) => '$value'),
        filename: 'report.json',
        contentType: MediaType('application', 'json'),
      ),
    )
    ..files.add(
      http.MultipartFile.fromString(
        'widget_tree',
        _widgetTree(app),
        filename: 'widget_tree.txt',
        contentType: MediaType('text', 'plain'),
      ),
    );
  if (screenshot != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'screenshot',
        screenshot,
        filename: 'screenshot.png',
        contentType: MediaType('image', 'png'),
      ),
    );
  }
  final response = await request.send();
  await response.stream.drain<void>();
  if (response.statusCode < 200 || response.statusCode > 299) {
    throw HttpException('$url answered ${response.statusCode}');
  }
}

Future<Map<String, Object?>> _report(
  GlobalKey app, {
  required String? stage,
  required FutureOr<Object?> Function()? database,
}) async {
  final context = app.currentContext;
  final media = context == null ? null : MediaQuery.maybeOf(context);
  // package_info_plus keeps what the platform said.
  final info = await PackageInfo.fromPlatform();
  final device = {
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
    'osVersion': kIsWeb ? '' : Platform.operatingSystemVersion,
    'locale': WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
    if (media != null) ...{
      'size': {'width': media.size.width, 'height': media.size.height},
      'pixelRatio': media.devicePixelRatio,
      'textScale': media.textScaler.scale(1),
      'brightness': media.platformBrightness.name,
    },
  };
  return {
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'app': {
      'packageName': info.packageName,
      'version': info.version,
      'buildNumber': info.buildNumber,
      'stage': ?stage,
    },
    'device': device,
    'blocs': SmileyfaceFeedbackBlocObserver.instance.toJson(),
    'database': await _database(database),
  };
}

Future<Object?> _database(FutureOr<Object?> Function()? database) async {
  if (database == null) return null;
  try {
    return await database();
  } on Object catch (error) {
    return {'error': '$error'};
  }
}

/// The widgets below [app]. A widget with one child continues the line with
/// `>`, each child of a widget with more starts an indented line. Unlike
/// debugDumpApp it works in release builds.
String _widgetTree(GlobalKey app) {
  final tree = StringBuffer();
  void visit(Element element, int depth) {
    final line = <String>[];
    var children = [element];
    while (children.length == 1) {
      final Widget(:runtimeType, :key) = children.single.widget;
      line.add('$runtimeType${key == null ? '' : ' $key'}');
      final next = <Element>[];
      children.single.visitChildren(next.add);
      children = next;
    }
    tree.writeln('${' ' * depth}${line.join(' > ')}');
    for (final child in children) {
      visit(child, depth + 1);
    }
  }

  if (app.currentContext case final Element element) visit(element, 0);
  return tree.toString();
}
