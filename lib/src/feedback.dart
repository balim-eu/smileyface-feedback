// The feedback of staging builds: testers shake the device and send a
// message, typed or dictated, and an annotated screenshot together with the
// state of the app to a URL.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, HttpException, Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shake/shake.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'config.dart';
part 'diagnostics.dart';
part 'dictation.dart';
part 'editor.dart';
part 'intro.dart';
part 'overlay.dart';
part 'panel.dart';
part 'texts.dart';

final _logger = Logger('smileyface_feedback');
