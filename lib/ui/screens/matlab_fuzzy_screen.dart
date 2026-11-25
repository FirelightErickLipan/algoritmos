import 'package:flutter/material.dart';

import '../widgets/video_resource_card.dart';
import '../widgets/web_explanation_navbar.dart';
import 'matlab_lab_screen.dart';

/// Color de acento de la sección MATLAB / Lógica Difusa.
const Color _kMatlabAccent = Color(0xFFFF7043);

/// Pestaña de introducción a Lógica Difusa con MATLAB.
///
/// Sigue la misma estructura que las demás pestañas explicativas
/// (Johnson, Asignación, ...): hero, divisiones alternadas con tarjetas
/// explicativas, videos de apoyo y una tarjeta final con el botón
/// "Ir a MATLAB".
class MatlabFuzzyScreen extends StatelessWidget {
  const MatlabFuzzyScreen({super.key});

  /// Abre el laboratorio MATLAB (puente local + archivo .fis).
  void _goToMatlab(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MatlabLabScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WebExplanationShell(
      activePage: ExplanationWebPage.matlab,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // DIVISION 0: Hero
            _HeroSection(onGoToMatlab: () => _goToMatlab(context)),

            // DIVISION 1: Concepto + video introductorio
            _Division(
              color: colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ConceptCard(),
                  SizedBox(height: 36),
                  _FuzzyStagesSection(),
                  SizedBox(height: 36),
                  VideoResourceCard(
                    title: 'Video 1: ¿Qué es la Lógica Difusa?',
                    description:
                        'Funciones de membresía, reglas y control difuso explicados desde cero para entender la idea antes de abrir MATLAB.',
                    videoUrl: 'https://www.youtube.com/watch?v=4uyTQtU_JEY',
                    durationOrAuthor: 'Introducción conceptual',
                  ),
                ],
              ),
            ),

            // DIVISION 2: Nuestro sistema difuso
            _Division(
              color: colorScheme.surfaceContainerLow,
              bordered: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _OurSystemSection(),
                  SizedBox(height: 36),
                  _RulesCard(),
                  SizedBox(height: 48),
                  VideoResourceCard(
                    title: 'Video 2: Tutorial de Lógica Fuzzy en MATLAB',
                    description:
                        'Recorrido por el Fuzzy Logic Toolbox: cómo definir entradas, salidas, funciones de membresía y reglas en MATLAB.',
                    videoUrl: 'https://www.youtube.com/watch?v=BptosN9sePc',
                    durationOrAuthor: 'MATLAB paso a paso',
                  ),
                ],
              ),
            ),

            // DIVISION 3: Flujo de trabajo con MATLAB
            _Division(
              color: colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _WorkflowSection(),
                  SizedBox(height: 36),
                  _CodeCard(),
                  SizedBox(height: 48),
                  VideoResourceCard(
                    title: 'Video 3: Uso de Fuzzy en MATLAB (actividad guiada)',
                    description:
                        'Ejemplo práctico de un sistema difuso construido y evaluado en MATLAB, útil para repasar el flujo que usaremos aquí.',
                    videoUrl: 'https://www.youtube.com/watch?v=nPrAmFtI1xw',
                    durationOrAuthor: 'Ejemplo aplicado',
                  ),
                ],
              ),
            ),

            // DIVISION 4: Requisitos + llamada a la acción
            _Division(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              bordered: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RequirementsCard(),
                  const SizedBox(height: 36),
                  _CtaCard(onGoToMatlab: () => _goToMatlab(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenedor de división (ancho completo + contenido centrado a 1100px)
// ---------------------------------------------------------------------------

class _Division extends StatelessWidget {
  final Color color;
  final bool bordered;
  final Widget child;

  const _Division({
    required this.color,
    required this.child,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: bordered
            ? Border.symmetric(
                horizontal: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              )
            : null,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final VoidCallback onGoToMatlab;

  const _HeroSection({required this.onGoToMatlab});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kMatlabAccent.withValues(alpha: 0.25),
            colorScheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _kMatlabAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.science_rounded,
                        size: 16,
                        color: _kMatlabAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sistemas de Inferencia Difusa',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kMatlabAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Lógica Difusa con MATLAB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width > 700 ? 42 : 30,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 750),
                  child: Text(
                    'No todo es verdadero o falso. La lógica difusa permite razonar con grados de verdad, como "interés bueno" o "infraestructura regular", para tomar decisiones parecidas a las de una persona.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width > 700 ? 18 : 15,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _MatlabLaunchButton(onPressed: onGoToMatlab),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatlabLaunchButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool filled;

  const _MatlabLaunchButton({required this.onPressed, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? _kMatlabAccent : Colors.white,
        foregroundColor: filled ? Colors.white : _kMatlabAccent,
        elevation: 3,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 26,
          vertical: isMobile ? 12 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.rocket_launch_rounded, size: isMobile ? 18 : 20),
      label: Text(
        'Ir a MATLAB',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 13 : 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas base reutilizables
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionHeader({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: _kMatlabAccent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final String description;

  const _InfoTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _kMatlabAccent.withValues(alpha: 0.18),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _kMatlabAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kMatlabAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distribuye tarjetas en 1, 2 o 3 columnas según el ancho disponible.
class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;

  const _ResponsiveGrid({required this.children, this.maxColumns = 2});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cols = 1;
        if (w >= 900 && maxColumns >= 3) {
          cols = 3;
        } else if (w >= 640 && maxColumns >= 2) {
          cols = 2;
        }
        const gap = 16.0;
        final itemWidth = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in children) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// División 1: concepto
// ---------------------------------------------------------------------------

class _ConceptCard extends StatelessWidget {
  const _ConceptCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kMatlabAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: _kMatlabAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DE "SÍ / NO" A "QUÉ TANTO"',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: _kMatlabAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¿Qué es la lógica difusa?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Text(
            'En la lógica clásica algo es verdadero (1) o falso (0). En la lógica difusa un valor puede pertenecer a varios conjuntos a la vez, con un grado entre 0 y 1.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Por ejemplo, un interés de 7 sobre 10 puede ser "Regular" en un 40 % y "Bueno" en un 60 %. Así se modelan conceptos vagos del lenguaje humano sin forzar un corte exacto entre ellos.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuzzyStagesSection extends StatelessWidget {
  const _FuzzyStagesSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'CÓMO RAZONA UN SISTEMA DIFUSO',
          title: 'Las 4 etapas de un sistema Mamdani',
        ),
        SizedBox(height: 24),
        _ResponsiveGrid(
          children: [
            _InfoTile(
              number: '1',
              title: 'Fuzzificación',
              subtitle: 'Número → grados de pertenencia',
              description:
                  'Cada entrada numérica se evalúa con sus funciones de membresía (gaussianas, trapezoidales, etc.) para saber a qué conjuntos pertenece y en qué grado.',
            ),
            _InfoTile(
              number: '2',
              title: 'Evaluación de reglas',
              subtitle: 'SI ... Y ... ENTONCES ...',
              description:
                  'Las reglas combinan las condiciones. El operador AND toma el mínimo de los grados, y el resultado recorta el conjunto de salida (implicación).',
            ),
            _InfoTile(
              number: '3',
              title: 'Agregación',
              subtitle: 'Unir todas las reglas activas',
              description:
                  'Las salidas recortadas de todas las reglas se unen en una sola figura, tomando el máximo en cada punto.',
            ),
            _InfoTile(
              number: '4',
              title: 'Defuzzificación',
              subtitle: 'Figura → número final',
              description:
                  'La figura resultante se convierte en un único valor. El método más usado es el centroide: el "centro de gravedad" del área.',
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// División 2: nuestro sistema (basado en FUZZY_IDK.fis)
// ---------------------------------------------------------------------------

class _OurSystemSection extends StatelessWidget {
  const _OurSystemSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'EL SISTEMA QUE VAMOS A ABRIR EN MATLAB',
          title: 'Rendimiento académico (FUZZY IDK)',
        ),
        SizedBox(height: 12),
        _PlainText(
          'Es un sistema Mamdani con 3 entradas, 1 salida y 27 reglas. Estima el rendimiento académico a partir del interés del estudiante, la calidad docente y la infraestructura.',
        ),
        SizedBox(height: 24),
        _ResponsiveGrid(
          maxColumns: 2,
          children: [
            _VariableCard(
              kind: 'ENTRADA 1',
              name: 'interes',
              range: 'Rango 0 – 10',
              type: 'Gaussianas',
              labels: ['Malo', 'Regular', 'Bueno'],
            ),
            _VariableCard(
              kind: 'ENTRADA 2',
              name: 'calidad_docente',
              range: 'Rango 0 – 100',
              type: 'Trapezoidales',
              labels: ['Mala', 'Regular', 'Buena'],
            ),
            _VariableCard(
              kind: 'ENTRADA 3',
              name: 'infrastructura',
              range: 'Rango 0 – 100',
              type: 'Trapezoidales',
              labels: ['Mala', 'Regular', 'Buena'],
            ),
            _VariableCard(
              kind: 'SALIDA',
              name: 'rendimientoacademico',
              range: 'Rango 0 – 100',
              type: 'Gaussianas',
              labels: ['Pésimo', 'Regular', 'Excelente'],
              isOutput: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _PlainText extends StatelessWidget {
  final String text;

  const _PlainText(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _VariableCard extends StatelessWidget {
  final String kind;
  final String name;
  final String range;
  final String type;
  final List<String> labels;
  final bool isOutput;

  const _VariableCard({
    required this.kind,
    required this.name,
    required this.range,
    required this.type,
    required this.labels,
    this.isOutput = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isOutput ? colorScheme.primary : _kMatlabAccent;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$range · $type',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in labels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rule_rounded, color: colorScheme.primary, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cómo se ven las reglas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las 27 reglas cubren todas las combinaciones de las 3 entradas (3 × 3 × 3). Por ejemplo:\n\n'
                  '• SI interés es Malo ENTONCES rendimiento es Pésimo.\n'
                  '• SI interés es Regular ENTONCES rendimiento es Regular.\n'
                  '• SI interés es Bueno Y calidad docente es Buena ENTONCES rendimiento es Excelente.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// División 3: flujo de trabajo en MATLAB
// ---------------------------------------------------------------------------

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'QUÉ HARÁS EN EL LABORATORIO',
          title: 'De la app a MATLAB y de vuelta',
        ),
        SizedBox(height: 24),
        _ResponsiveGrid(
          maxColumns: 3,
          children: [
            _InfoTile(
              number: '1',
              title: 'Elige tu archivo',
              subtitle: 'Archivo .fis',
              description:
                  'Pulsa "Ir a MATLAB" y selecciona el archivo .fis que contiene tu sistema difuso. Puedes usar el de ejemplo FUZZY_IDK.',
            ),
            _InfoTile(
              number: '2',
              title: 'Se abre MATLAB',
              subtitle: 'Fuzzy Logic Designer',
              description:
                  'La app lanza MATLAB en tu computadora con el sistema ya cargado, listo para editar funciones de membresía y reglas.',
            ),
            _InfoTile(
              number: '3',
              title: 'Guarda tus cambios',
              subtitle: 'De vuelta a la app',
              description:
                  'Exporta el archivo desde MATLAB y tráelo de regreso a la app para descargarlo con tus modificaciones.',
            ),
          ],
        ),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard();

  static const String _code = '''fis = readfis('FUZZY_IDK.fis');   % cargar el sistema
fuzzyLogicDesigner(fis)             % editor visual
ruleview(fis)                       % ver reglas en vivo
gensurf(fis)                        % superficie de salida
evalfis(fis, [7 80 60])             % evaluar un caso''';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 18,
                color: colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 8),
              Text(
                'Comandos básicos de MATLAB',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onInverseSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              _code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                height: 1.6,
                color: colorScheme.onInverseSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// División 4: requisitos y CTA
// ---------------------------------------------------------------------------

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const items = [
      'MATLAB instalado en tu computadora, con el Fuzzy Logic Toolbox.',
      'Haber iniciado la aplicación con el archivo iniciar.bat, que prepara la conexión con MATLAB.',
      'Un archivo .fis de tu computadora (o puedes usar el ejemplo incluido).',
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Antes de empezar necesitas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: _kMatlabAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  final VoidCallback onGoToMatlab;

  const _CtaCard({required this.onGoToMatlab});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kMatlabAccent.withValues(alpha: 0.22),
            colorScheme.primaryContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kMatlabAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '¿Listo para probar tu sistema difuso?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Abre el laboratorio, carga tu archivo .fis y ábrelo directamente en MATLAB.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          _MatlabLaunchButton(onPressed: onGoToMatlab, filled: true),
        ],
      ),
    );
  }
}
