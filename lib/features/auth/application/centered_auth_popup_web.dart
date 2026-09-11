import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Firebase Auth centraliza o popup na *tela* (`screen.availWidth`), não na
/// janela do browser — em monitores largos o diálogo do Google fica à esquerda.
/// Interceptamos `window.open` e recentramos na janela atual.
Future<T> withCenteredAuthPopup<T>(Future<T> Function() action) async {
  final jsWindow = web.window as JSObject;
  final previous = jsWindow.getProperty('open'.toJS);

  jsWindow.setProperty(
    'open'.toJS,
    (JSAny? url, JSAny? name, JSAny? features) {
      final featuresStr = features == null ? '' : (features.dartify()?.toString() ?? '');
      final centeredFeatures = _featuresCenteredOnBrowser(featuresStr);
      final opened = (previous as JSFunction).callAsFunction(
        jsWindow,
        url ?? ''.toJS,
        name ?? ''.toJS,
        centeredFeatures.toJS,
      );
      _moveToBrowserCenter(opened, featuresStr);
      return opened;
    }.toJS,
  );

  try {
    return await action();
  } finally {
    jsWindow.setProperty('open'.toJS, previous);
  }
}

String _featuresCenteredOnBrowser(String features) {
  final width = _featureInt(features, 'width') ?? 500;
  final height = _featureInt(features, 'height') ?? 600;
  final left = _browserCenterLeft(width);
  final top = _browserCenterTop(height);

  var cleaned = features
      .replaceAll(RegExp(r'left=-?\d+'), '')
      .replaceAll(RegExp(r'top=-?\d+'), '')
      .replaceAll(RegExp(r',{2,}'), ',')
      .replaceAll(RegExp(r'^,'), '')
      .replaceAll(RegExp(r',$'), '');
  if (cleaned.isNotEmpty && !cleaned.endsWith(',')) {
    cleaned = '$cleaned,';
  }
  return '${cleaned}left=$left,top=$top';
}

void _moveToBrowserCenter(JSAny? opened, String features) {
  if (opened == null) return;
  try {
    final width = _featureInt(features, 'width') ?? 500;
    final height = _featureInt(features, 'height') ?? 600;
    final win = opened as web.Window;
    win.moveTo(_browserCenterLeft(width), _browserCenterTop(height));
  } catch (_) {
    // Alguns browsers bloqueiam moveTo; features já tentam posicionar.
  }
}

int _browserCenterLeft(int width) {
  final screenLeft = web.window.screenX;
  final outer = web.window.outerWidth;
  return screenLeft + ((outer - width) / 2).round();
}

int _browserCenterTop(int height) {
  final screenTop = web.window.screenY;
  final outer = web.window.outerHeight;
  return screenTop + ((outer - height) / 2).round();
}

int? _featureInt(String features, String key) {
  if (features.isEmpty) return null;
  final match = RegExp('$key=(-?\\d+)').firstMatch(features);
  return match == null ? null : int.tryParse(match.group(1)!);
}
