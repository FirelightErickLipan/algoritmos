// Puente local entre la app web (Flutter) y MATLAB.
//
// Uso (desde la raíz del proyecto):
//   dart run tool/matlab_helper.dart
//
// Opciones:
//   --port 8765                       Puerto local (por defecto 8765)
//   --matlab "C:\Program Files\MATLAB\R2026b"   Ruta por defecto de MATLAB
//   --allow-origin https://mi-sitio   Origen web adicional permitido
//
// Seguridad:
//  - Escucha SOLO en la máquina local (loopback).
//  - Solo acepta peticiones de http(s)://localhost o 127.0.0.1 (o los
//    orígenes añadidos con --allow-origin).
//  - Solo ejecuta un archivo llamado matlab / matlab.exe.
//  - El comando que se envía a MATLAB es una plantilla fija; el contenido
//    que llega de la web nunca se ejecuta, solo se guarda como archivo .fis.

import 'dart:convert';
import 'dart:io';

const int _maxBodyBytes = 3 * 1024 * 1024; // 3 MB

final RegExp _localOrigin = RegExp(r'^https?://(localhost|127\.0\.0\.1)(:\d+)?$');
final List<String> _extraOrigins = [];
String? _defaultMatlab;
late final Directory _workDir;

Future<void> main(List<String> args) async {
  var port = 8765;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--port':
        port = int.parse(args[++i]);
      case '--matlab':
        _defaultMatlab = args[++i];
      case '--allow-origin':
        _extraOrigins.add(args[++i]);
    }
  }

  final home = Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.systemTemp.path;
  _workDir = Directory('$home${Platform.pathSeparator}.nodos_matlab');
  if (!_workDir.existsSync()) _workDir.createSync(recursive: true);

  HttpServer server;
  try {
    // Doble pila (IPv4 + IPv6) solo en loopback.
    server = await HttpServer.bind(
      InternetAddress.loopbackIPv6,
      port,
      v6Only: false,
    );
  } catch (_) {
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      stdout.writeln(
        'El puente MATLAB ya estaba en ejecución en el puerto $port. Nada que hacer.',
      );
      exit(0);
    }
  }

  final detected = _resolveMatlab(_defaultMatlab);
  stdout.writeln('==============================================');
  stdout.writeln(' Puente MATLAB activo en http://localhost:$port');
  stdout.writeln(' Carpeta de trabajo: ${_workDir.path}');
  stdout.writeln(' MATLAB detectado:   ${detected ?? "(no encontrado)"}');
  stdout.writeln(' Deja esta ventana abierta. Ctrl+C para cerrar.');
  stdout.writeln('==============================================');

  await for (final req in server) {
    _handle(req);
  }
}

// ---------------------------------------------------------------------------
// Manejo de peticiones
// ---------------------------------------------------------------------------

Future<void> _handle(HttpRequest req) async {
  final res = req.response;
  try {
    final origin = req.headers.value('origin');
    if (origin != null && !_originAllowed(origin)) {
      await _json(res, 403, {'error': 'Origen no permitido: $origin'});
      return;
    }
    _cors(res, origin);

    if (req.method == 'OPTIONS') {
      res.statusCode = 204;
      await res.close();
      return;
    }

    // Defensa extra: desde un navegador exigimos la cabecera propia.
    if (origin != null && req.headers.value('x-nodos-client') == null) {
      await _json(res, 403, {'error': 'Falta la cabecera X-Nodos-Client.'});
      return;
    }

    final route = '${req.method} ${req.uri.path}';
    switch (route) {
      case 'GET /status':
        await _status(res);
      case 'POST /open':
        await _open(req);
      case 'GET /files':
        await _files(res);
      case 'GET /file':
        await _file(req);
      default:
        await _json(res, 404, {'error': 'Ruta no encontrada: $route'});
    }
  } catch (e) {
    try {
      await _json(res, 500, {'error': 'Error interno del puente: $e'});
    } catch (_) {}
  }
}

Future<void> _status(HttpResponse res) async {
  await _json(res, 200, {
    'ok': true,
    'version': 1,
    'os': Platform.operatingSystem,
    'workDir': _workDir.path,
    'matlabPath': _resolveMatlab(_defaultMatlab),
  });
}

Future<void> _open(HttpRequest req) async {
  final res = req.response;
  if (req.contentLength > _maxBodyBytes) {
    await _json(res, 413, {'error': 'El archivo es demasiado grande.'});
    return;
  }
  final raw = await utf8.decoder.bind(req).join();
  if (raw.length > _maxBodyBytes) {
    await _json(res, 413, {'error': 'El archivo es demasiado grande.'});
    return;
  }

  final body = jsonDecode(raw);
  if (body is! Map || body['content'] is! String || body['name'] is! String) {
    await _json(res, 400, {'error': 'Petición inválida: faltan name/content.'});
    return;
  }

  final userPath = (body['matlabPath'] as String?)?.trim();
  final hasUserPath = userPath != null && userPath.isNotEmpty;
  final exe = _resolveMatlab(hasUserPath ? userPath : _defaultMatlab);
  if (exe == null) {
    await _json(res, 400, {
      'code': 'matlab_not_found',
      'error': hasUserPath
          ? 'No encontré matlab en "$userPath". Revisa la ruta (puede ser la '
              'carpeta de instalación, p. ej. C:\\Program Files\\MATLAB\\R2026b, '
              'o el archivo matlab.exe).'
          : 'No pude detectar MATLAB. Escribe la ruta de instalación en la app.',
    });
    return;
  }

  final fileName = _safeName(body['name'] as String);
  File('${_workDir.path}${Platform.pathSeparator}$fileName')
      .writeAsStringSync(body['content'] as String, encoding: utf8);

  // Script fijo que MATLAB ejecutará al arrancar (el nombre está saneado).
  final script = '''
% Generado automáticamente por matlab_helper.dart
try
    fis = readfis('$fileName');
    fuzzyLogicDesigner(fis);
    fprintf('Sistema difuso cargado desde: %s\\n', fullfile(pwd, '$fileName'));
catch ME
    disp(getReport(ME));
end
''';
  File('${_workDir.path}${Platform.pathSeparator}nodos_open.m')
      .writeAsStringSync(script, encoding: utf8);

  try {
    await Process.start(
      exe,
      ['-sd', _workDir.path, '-r', 'nodos_open'],
      workingDirectory: _workDir.path,
      mode: ProcessStartMode.detached,
    );
  } catch (e) {
    await _json(res, 500, {'error': 'No se pudo lanzar MATLAB: $e'});
    return;
  }

  stdout.writeln('[open] $fileName -> $exe');
  await _json(res, 200, {
    'ok': true,
    'file': fileName,
    'matlab': exe,
    'workDir': _workDir.path,
  });
}

Future<void> _files(HttpResponse res) async {
  final list = <Map<String, Object>>[];
  for (final e in _workDir.listSync()) {
    if (e is File && e.path.toLowerCase().endsWith('.fis')) {
      final stat = e.statSync();
      list.add({
        'name': e.uri.pathSegments.last,
        'modified': stat.modified.toUtc().toIso8601String(),
        'size': stat.size,
      });
    }
  }
  list.sort(
    (a, b) => (b['modified'] as String).compareTo(a['modified'] as String),
  );
  await _json(res, 200, {'files': list});
}

Future<void> _file(HttpRequest req) async {
  final res = req.response;
  final name = req.uri.queryParameters['name'];
  if (name == null || name.isEmpty) {
    await _json(res, 400, {'error': 'Falta el parámetro name.'});
    return;
  }
  final file = File('${_workDir.path}${Platform.pathSeparator}${_safeName(name)}');
  if (!file.existsSync()) {
    await _json(res, 404, {'error': 'No existe ese archivo en la carpeta de trabajo.'});
    return;
  }
  await _json(res, 200, {
    'name': file.uri.pathSegments.last,
    'modified': file.statSync().modified.toUtc().toIso8601String(),
    'content': utf8.decode(file.readAsBytesSync(), allowMalformed: true),
  });
}

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

bool _originAllowed(String origin) =>
    _localOrigin.hasMatch(origin) || _extraOrigins.contains(origin);

void _cors(HttpResponse res, String? origin) {
  if (origin != null) {
    res.headers.set('Access-Control-Allow-Origin', origin);
    res.headers.set('Vary', 'Origin');
  }
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type, X-Nodos-Client');
  res.headers.set('Access-Control-Allow-Private-Network', 'true');
  res.headers.set('Access-Control-Max-Age', '600');
}

Future<void> _json(HttpResponse res, int code, Object body) async {
  res.statusCode = code;
  res.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
  res.add(utf8.encode(jsonEncode(body)));
  await res.close();
}

/// Deja solo caracteres seguros y fuerza la extensión .fis (sin rutas).
String _safeName(String raw) {
  var n = raw.split(RegExp(r'[\\/]')).last.trim();
  n = n.replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '_');
  if (n.length > 80) n = n.substring(n.length - 80);
  if (!n.toLowerCase().endsWith('.fis')) n = '$n.fis';
  if (n.startsWith('.')) n = 'f$n';
  return n;
}

String get _exeName => Platform.isWindows ? 'matlab.exe' : 'matlab';

/// Acepta la carpeta de instalación o el ejecutable. Si [userPath] es nulo,
/// intenta detectar la instalación más reciente en las rutas habituales.
String? _resolveMatlab(String? userPath) {
  final candidates = <String>[];
  if (userPath != null && userPath.trim().isNotEmpty) {
    var p = userPath.trim();
    if (p.length > 1 && p.startsWith('"') && p.endsWith('"')) {
      p = p.substring(1, p.length - 1);
    }
    final lower = p.toLowerCase();
    if (lower.endsWith('matlab.exe') || lower.endsWith('${Platform.pathSeparator}matlab')) {
      candidates.add(p);
    } else {
      final sep = Platform.pathSeparator;
      candidates.add('$p${sep}bin$sep$_exeName');
      // macOS: /Applications/MATLAB_R2026b.app
      candidates.add('$p${sep}bin${sep}matlab');
    }
  } else {
    candidates.addAll(_autoDetect());
  }
  for (final c in candidates) {
    if (File(c).existsSync() && _isMatlabExe(c)) return c;
  }
  return null;
}

bool _isMatlabExe(String path) {
  final base = path.split(RegExp(r'[\\/]')).last.toLowerCase();
  return base == 'matlab' || base == 'matlab.exe';
}

List<String> _autoDetect() {
  final roots = <String>[];
  if (Platform.isWindows) {
    roots.addAll([r'C:\Program Files\MATLAB', r'C:\Program Files (x86)\MATLAB']);
  } else if (Platform.isMacOS) {
    roots.add('/Applications');
  } else {
    roots.addAll(['/usr/local/MATLAB', '/opt/MATLAB']);
  }

  final found = <String>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    final entries = dir
        .listSync()
        .whereType<Directory>()
        .where((d) {
          final name = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
          return Platform.isMacOS ? name.startsWith('MATLAB_') : true;
        })
        .map((d) => d.path)
        .toList()
      ..sort((a, b) => b.compareTo(a)); // la versión más nueva primero
    for (final e in entries) {
      found.add('$e${Platform.pathSeparator}bin${Platform.pathSeparator}$_exeName');
    }
  }
  return found;
}
