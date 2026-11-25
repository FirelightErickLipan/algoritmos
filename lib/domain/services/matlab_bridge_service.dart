import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error legible para mostrar al usuario.
class MatlabBridgeException implements Exception {
  final String message;

  /// Código opcional enviado por el puente (p. ej. `matlab_not_found`).
  final String? code;

  const MatlabBridgeException(this.message, {this.code});

  @override
  String toString() => message;
}

class BridgeStatus {
  final String? detectedMatlabPath;
  final String? workDir;
  final String? os;

  const BridgeStatus({this.detectedMatlabPath, this.workDir, this.os});
}

class BridgeFile {
  final String name;
  final DateTime modified;
  final int size;

  const BridgeFile({
    required this.name,
    required this.modified,
    required this.size,
  });
}

class BridgeOpenResult {
  final String fileName;
  final String matlabExecutable;

  const BridgeOpenResult({
    required this.fileName,
    required this.matlabExecutable,
  });
}

/// Cliente HTTP del programa puente local (tool/matlab_helper.dart).
class MatlabBridgeService {
  static const String defaultBaseUrl = 'http://localhost:8765';

  final String baseUrl;
  final http.Client _client;

  MatlabBridgeService({this.baseUrl = defaultBaseUrl, http.Client? client})
    : _client = client ?? http.Client();

  static const Map<String, String> _baseHeaders = {'X-Nodos-Client': '1'};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<BridgeStatus> status() async {
    final data = await _send(
      () => _client.get(_uri('/status'), headers: _baseHeaders),
    );
    return BridgeStatus(
      detectedMatlabPath: data['matlabPath'] as String?,
      workDir: data['workDir'] as String?,
      os: data['os'] as String?,
    );
  }

  Future<BridgeOpenResult> open({
    required String name,
    required String content,
    String? matlabPath,
  }) async {
    final data = await _send(
      () => _client.post(
        _uri('/open'),
        headers: {..._baseHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'content': content,
          'matlabPath': matlabPath ?? '',
        }),
      ),
    );
    return BridgeOpenResult(
      fileName: data['file'] as String,
      matlabExecutable: data['matlab'] as String,
    );
  }

  Future<List<BridgeFile>> listFiles() async {
    final data = await _send(
      () => _client.get(_uri('/files'), headers: _baseHeaders),
    );
    final list = (data['files'] as List).cast<Map<String, dynamic>>();
    return [
      for (final f in list)
        BridgeFile(
          name: f['name'] as String,
          modified: DateTime.parse(f['modified'] as String).toLocal(),
          size: f['size'] as int,
        ),
    ];
  }

  Future<String> readFile(String name) async {
    final data = await _send(
      () => _client.get(_uri('/file', {'name': name}), headers: _baseHeaders),
    );
    return data['content'] as String;
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const MatlabBridgeException(
        'El puente no respondió a tiempo. ¿Sigue abierta la ventana del puente?',
      );
    } catch (_) {
      throw const MatlabBridgeException(
        'No se pudo conectar con el puente. Ejecuta '
        '"dart run tool/matlab_helper.dart" en una terminal y vuelve a intentar.',
      );
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (res.statusCode != 200) {
      throw MatlabBridgeException(
        (data['error'] as String?) ?? 'Error del puente (${res.statusCode}).',
        code: data['code'] as String?,
      );
    }
    return data;
  }
}
