import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Abre el selector de archivos del navegador y devuelve el nombre y el
/// contenido de texto del archivo elegido (o null si se cancela).
Future<({String name, String content})?> pickTextFile({
  String accept = '.fis',
}) {
  final completer = Completer<({String name, String content})?>();

  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0)!;
      file.text().toDart.then((text) {
        if (!completer.isCompleted) {
          completer.complete((name: file.name, content: text.toDart));
        }
      });
    }).toJS,
  );

  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }).toJS,
  );

  input.click();
  return completer.future;
}
