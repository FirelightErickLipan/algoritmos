import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/fis_file_picker_stub.dart'
    if (dart.library.js_interop) '../../core/utils/fis_file_picker_web.dart';
import '../../core/utils/platform_file_saver_stub.dart'
    if (dart.library.js_interop) '../../core/utils/platform_file_saver_web.dart'
    if (dart.library.io) '../../core/utils/platform_file_saver_io.dart';
import '../../domain/services/matlab_bridge_service.dart';

/// Resultado de una acción del usuario: error (rojo), mensaje (info) o nada
/// (por ejemplo, si cancela el selector de archivos).
class MatlabActionResult {
  final String? error;
  final String? message;

  const MatlabActionResult.ok([this.message]) : error = null;
  const MatlabActionResult.fail(this.error) : message = null;

  bool get isError => error != null;
}

class MatlabState {
  final bool checking;
  final bool bridgeOnline;
  final bool busy;

  /// Ruta manual de MATLAB. Solo se usa si la detección automática falla.
  final String matlabPath;

  /// true cuando el puente no pudo encontrar MATLAB por sí solo.
  final bool needsPath;

  final String? fileName;
  final String? fileContent;
  final bool openedInMatlab;
  final DateTime? openedAt;

  const MatlabState({
    this.checking = false,
    this.bridgeOnline = false,
    this.busy = false,
    this.matlabPath = '',
    this.needsPath = false,
    this.fileName,
    this.fileContent,
    this.openedInMatlab = false,
    this.openedAt,
  });

  bool get hasFile => fileName != null && fileContent != null;

  MatlabState copyWith({
    bool? checking,
    bool? bridgeOnline,
    bool? busy,
    String? matlabPath,
    bool? needsPath,
    String? fileName,
    String? fileContent,
    bool? openedInMatlab,
    DateTime? openedAt,
  }) {
    return MatlabState(
      checking: checking ?? this.checking,
      bridgeOnline: bridgeOnline ?? this.bridgeOnline,
      busy: busy ?? this.busy,
      matlabPath: matlabPath ?? this.matlabPath,
      needsPath: needsPath ?? this.needsPath,
      fileName: fileName ?? this.fileName,
      fileContent: fileContent ?? this.fileContent,
      openedInMatlab: openedInMatlab ?? this.openedInMatlab,
      openedAt: openedAt ?? this.openedAt,
    );
  }
}

class MatlabNotifier extends Notifier<MatlabState> {
  static const String _tag = 'MatlabNotifier';
  static const String _prefPathKey = 'matlab_install_path';

  static const String _offlineMessage =
      'No se pudo conectar con el componente local que abre MATLAB. '
      'Inicia la aplicación con iniciar.bat y vuelve a intentar.';

  final MatlabBridgeService _service = MatlabBridgeService();

  @override
  MatlabState build() {
    Future.microtask(_init);
    return const MatlabState();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefPathKey);
      if (saved != null && saved.isNotEmpty) {
        state = state.copyWith(matlabPath: saved);
      }
    } catch (_) {}
    await checkBridge();
  }

  /// Comprueba (sin mostrar nada al usuario) si el puente local responde.
  Future<bool> checkBridge() async {
    if (state.checking) return state.bridgeOnline;
    state = state.copyWith(checking: true);
    try {
      final status = await _service.status();
      state = state.copyWith(checking: false, bridgeOnline: true);
      AppLogger.i(_tag, 'Puente en línea. MATLAB: ${status.detectedMatlabPath}');
      return true;
    } on MatlabBridgeException catch (e) {
      AppLogger.w(_tag, 'Puente no disponible: ${e.message}');
      state = state.copyWith(checking: false, bridgeOnline: false);
      return false;
    }
  }

  Future<void> setMatlabPath(String value) async {
    final path = value.trim();
    state = state.copyWith(matlabPath: path);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPathKey, path);
    } catch (_) {}
  }

  /// Flujo principal: el usuario elige un .fis y se abre directo en MATLAB.
  Future<MatlabActionResult> pickAndOpen() async {
    final picked = await pickTextFile(accept: '.fis');
    if (picked == null) return const MatlabActionResult.ok(); // canceló
    return openFile(picked.name, picked.content);
  }

  /// Carga [content] como archivo actual y lo abre en MATLAB.
  Future<MatlabActionResult> openFile(String name, String content) async {
    if (!content.contains('[System]')) {
      return const MatlabActionResult.fail(
        'El archivo no parece un .fis válido (falta la sección [System]).',
      );
    }
    state = state.copyWith(
      fileName: name,
      fileContent: content,
      openedInMatlab: false,
    );
    return openInMatlab();
  }

  Future<MatlabActionResult> openInMatlab() async {
    if (!state.hasFile) {
      return const MatlabActionResult.fail('Primero elige un archivo .fis.');
    }
    state = state.copyWith(busy: true);
    try {
      if (!state.bridgeOnline) {
        final ok = await checkBridge();
        if (!ok) return const MatlabActionResult.fail(_offlineMessage);
      }
      final result = await _service.open(
        name: state.fileName!,
        content: state.fileContent!,
        matlabPath: state.matlabPath,
      );
      state = state.copyWith(
        fileName: result.fileName,
        openedInMatlab: true,
        openedAt: DateTime.now(),
        needsPath: false,
      );
      return const MatlabActionResult.ok(
        'Abriendo MATLAB... puede tardar unos segundos.',
      );
    } on MatlabBridgeException catch (e) {
      if (e.code == 'matlab_not_found') {
        state = state.copyWith(needsPath: true);
      }
      return MatlabActionResult.fail(e.message);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Busca el .fis más reciente guardado desde MATLAB y lo descarga.
  Future<MatlabActionResult> downloadEdited() async {
    final openedAt = state.openedAt;
    if (!state.openedInMatlab || openedAt == null) {
      return const MatlabActionResult.fail(
        'Primero abre un archivo en MATLAB.',
      );
    }
    state = state.copyWith(busy: true);
    try {
      final files = await _service.listFiles();
      final changed = files.where((f) => f.modified.isAfter(openedAt)).toList();
      if (changed.isEmpty) {
        return const MatlabActionResult.fail(
          'Aún no hay cambios guardados desde MATLAB. En MATLAB usa '
          'Export → To File y guarda el archivo en la carpeta que se abrió '
          '(Current Folder); luego vuelve aquí.',
        );
      }
      final newest = changed.first; // el puente las ordena de más nueva a vieja
      final content = await _service.readFile(newest.name);
      await savePlatformBytes(
        newest.name,
        Uint8List.fromList(utf8.encode(content)),
        mimeType: 'text/plain',
      );
      state = state.copyWith(fileName: newest.name, fileContent: content);
      return MatlabActionResult.ok('Descargado "${newest.name}" con tus cambios.');
    } on MatlabBridgeException catch (e) {
      return MatlabActionResult.fail(e.message);
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

final matlabProvider = NotifierProvider<MatlabNotifier, MatlabState>(
  MatlabNotifier.new,
);
