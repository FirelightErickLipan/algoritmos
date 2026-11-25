import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/matlab_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/web_explanation_navbar.dart';

const Color _kAccent = Color(0xFFFF7043);

/// Pantalla de uso: el usuario elige un .fis y se abre directamente en MATLAB.
/// Todo lo técnico (puente local, ruta de MATLAB) queda oculto y solo aparece
/// si algo falla.
class MatlabLabScreen extends ConsumerStatefulWidget {
  const MatlabLabScreen({super.key});

  @override
  ConsumerState<MatlabLabScreen> createState() => _MatlabLabScreenState();
}

class _MatlabLabScreenState extends ConsumerState<MatlabLabScreen> {
  late final TextEditingController _pathCtrl;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _pathCtrl = TextEditingController(text: ref.read(matlabProvider).matlabPath);

    // Mientras el componente local no responda, reintenta en silencio para que
    // el aviso desaparezca solo cuando se inicie.
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final s = ref.read(matlabProvider);
      if (!s.bridgeOnline && !s.checking) {
        ref.read(matlabProvider.notifier).checkBridge();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _pathCtrl.dispose();
    super.dispose();
  }

  void _show(MatlabActionResult result) {
    if (!mounted) return;
    if (result.isError) {
      AppToast.show(
        context,
        result.error!,
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 7),
      );
    } else if (result.message != null) {
      AppToast.show(context, result.message!, icon: Icons.check_circle_rounded);
    }
  }

  Future<void> _pickAndOpen() async {
    final result = await ref.read(matlabProvider.notifier).pickAndOpen();
    _show(result);
  }

  Future<void> _openSample() async {
    try {
      final text = await rootBundle.loadString('assets/fis/FUZZY_IDK.fis');
      final result = await ref
          .read(matlabProvider.notifier)
          .openFile('FUZZY_IDK.fis', text);
      _show(result);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context,
        'No se encontró el archivo de ejemplo en el proyecto.',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _saveAndRetry() async {
    final notifier = ref.read(matlabProvider.notifier);
    await notifier.setMatlabPath(_pathCtrl.text);
    final result = await notifier.openInMatlab();
    _show(result);
  }

  Future<void> _download() async {
    final result = await ref.read(matlabProvider.notifier).downloadEdited();
    _show(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = ref.watch(matlabProvider);

    ref.listen<String>(matlabProvider.select((st) => st.matlabPath), (_, next) {
      if (_pathCtrl.text != next) _pathCtrl.text = next;
    });

    return WebExplanationShell(
      activePage: ExplanationWebPage.matlab,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver a la introducción',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Abrir en MATLAB',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Aviso: componente local no iniciado
                  if (!s.bridgeOnline && !s.checking) ...[
                    _OfflineBanner(
                      onRetry: () =>
                          ref.read(matlabProvider.notifier).checkBridge(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Tarjeta principal
                  _MainCard(
                    busy: s.busy,
                    onPick: _pickAndOpen,
                    onSample: _openSample,
                  ),

                  // Archivo abierto + guardar
                  if (s.hasFile) ...[
                    const SizedBox(height: 18),
                    _OpenedCard(
                      name: s.fileName!,
                      content: s.fileContent!,
                      opened: s.openedInMatlab,
                      busy: s.busy,
                      onDownload: _download,
                    ),
                  ],

                  // Solo si no se encontró MATLAB automáticamente
                  if (s.needsPath) ...[
                    const SizedBox(height: 18),
                    _PathCard(
                      controller: _pathCtrl,
                      busy: s.busy,
                      onSave: _saveAndRetry,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? background;

  const _CardShell({required this.child, this.borderColor, this.background});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: background ?? colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ??
              colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}

class _MainCard extends StatelessWidget {
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onSample;

  const _MainCard({
    required this.busy,
    required this.onPick,
    required this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _CardShell(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science_rounded, size: 40, color: _kAccent),
          ),
          const SizedBox(height: 18),
          Text(
            'Selecciona tu sistema difuso',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un archivo .fis de tu computadora y se abrirá directamente en MATLAB.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: busy ? null : onPick,
            icon: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.folder_open_rounded),
            label: Text(busy ? 'Abriendo MATLAB...' : 'Seleccionar archivo .fis'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onSample,
            child: const Text('o probar con el ejemplo FUZZY_IDK'),
          ),
        ],
      ),
    );
  }
}

class _OpenedCard extends StatelessWidget {
  final String name;
  final String content;
  final bool opened;
  final bool busy;
  final VoidCallback onDownload;

  const _OpenedCard({
    required this.name,
    required this.content,
    required this.opened,
    required this.busy,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final systemName = RegExp(r"Name='([^']*)'").firstMatch(content)?.group(1);
    final rules = RegExp(r'NumRules=(\d+)').firstMatch(content)?.group(1);
    final inputs = RegExp(r'NumInputs=(\d+)').firstMatch(content)?.group(1);
    final outputs = RegExp(r'NumOutputs=(\d+)').firstMatch(content)?.group(1);
    final details = [
      if (systemName != null) systemName,
      if (inputs != null) '$inputs entradas',
      if (outputs != null) '$outputs salida(s)',
      if (rules != null) '$rules reglas',
    ].join(' · ');

    return _CardShell(
      borderColor: opened ? Colors.green.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                opened ? Icons.check_circle_rounded : Icons.description_rounded,
                color: opened ? Colors.green : _kAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (opened) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MATLAB se está abriendo con tu sistema. Si haces cambios, en MATLAB usa Export → To File y guarda con el mismo nombre en la carpeta que ya está abierta. Después pulsa "Guardar mi archivo".',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: busy ? null : onDownload,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Guardar mi archivo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _CardShell(
      background: Colors.orange.withValues(alpha: 0.12),
      borderColor: Colors.orange.withValues(alpha: 0.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.power_off_rounded, color: Colors.orange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Falta iniciar el componente que abre MATLAB',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cierra esta aplicación y ábrela de nuevo con el archivo iniciar.bat (doble clic). Esta pantalla se conectará sola en unos segundos.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar ahora'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSave;

  const _PathCard({
    required this.controller,
    required this.busy,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _CardShell(
      borderColor: Colors.orange.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No encontramos MATLAB automáticamente',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Indica la carpeta donde lo instalaste (se guarda para la próxima vez).',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Carpeta de MATLAB',
              hintText: r'C:\Program Files\MATLAB\R2026b',
            ),
            onSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: busy ? null : onSave,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('Guardar y abrir'),
          ),
        ],
      ),
    );
  }
}
