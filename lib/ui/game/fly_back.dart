import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../settings/app_theme.dart';

/// Um operador voando da linha da equação de volta para o seu botão.
class Flight {
  const Flight({required this.from, required this.to, required this.label});

  /// Retângulos em coordenadas globais.
  final Rect from;
  final Rect to;
  final String label;
}

/// Retângulo global do widget associado a [key], se estiver montado.
Rect? globalRectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Anima os operadores voltando para os seus botões no teclado.
///
/// A animação acontece em uma camada do [Overlay], então continua mesmo
/// depois de a linha da equação já ter sido reconstruída sem os operadores.
void playFlyBack(BuildContext context, List<Flight> flights) {
  if (flights.isEmpty || MediaQuery.disableAnimationsOf(context)) return;
  final overlay = Overlay.of(context);
  final scheme = Theme.of(context).colorScheme;
  final style = mathStyle(context, color: scheme.onSecondaryContainer);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyBackLayer(
      flights: flights,
      color: scheme.secondaryContainer,
      textStyle: style,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FlyBackLayer extends StatefulWidget {
  const _FlyBackLayer({
    required this.flights,
    required this.color,
    required this.textStyle,
    required this.onDone,
  });

  final List<Flight> flights;
  final Color color;
  final TextStyle textStyle;
  final VoidCallback onDone;

  @override
  State<_FlyBackLayer> createState() => _FlyBackLayerState();
}

class _FlyBackLayerState extends State<_FlyBackLayer>
    with SingleTickerProviderStateMixin {
  static const _flightMs = 520;
  static const _staggerMs = 45;

  late final AnimationController _controller;

  int get _totalMs =>
      _flightMs + _staggerMs * math.min(widget.flights.length - 1, 10);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final elapsed = _controller.value * _totalMs;
          return Stack(
            children: [
              for (final (i, flight) in widget.flights.indexed)
                _buildFlight(flight, elapsed - _staggerMs * math.min(i, 10)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFlight(Flight flight, double localMs) {
    final raw = (localMs / _flightMs).clamp(0.0, 1.0);
    if (raw >= 1) return const SizedBox.shrink();
    final t = Curves.easeInOutCubic.transform(raw);
    final rect = Rect.lerp(flight.from, flight.to, t)!;
    // Pequeno arco para cima durante o voo.
    final lift = math.sin(math.pi * t) * 36;
    return Positioned(
      left: rect.left,
      top: rect.top - lift,
      width: rect.width,
      height: rect.height,
      child: Opacity(
        opacity: raw < 0.85 ? 1 : (1 - raw) / 0.15,
        child: Transform.rotate(
          angle: math.sin(math.pi * t) * 0.35,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    flight.label,
                    textScaler: TextScaler.noScaling,
                    style: widget.textStyle.copyWith(fontSize: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
