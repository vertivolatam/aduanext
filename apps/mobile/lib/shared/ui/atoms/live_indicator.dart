/// Atom: live/reconnecting/offline indicator for the real-time stream.
///
/// Watches [dispatchStreamStateProvider] and renders a small
/// colored pill:
///   * Live         — green dot + "En vivo"
///   * Connecting   — amber pulsing dot + "Conectando..."
///   * Reconnecting — amber pulsing dot + "Reconectando..."
///   * Polling      — blue dot + "Actualizando cada 60s"
///   * Offline/idle — gray dot + "Sin conexión"
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/dispatch_stream_client.dart';
import '../../api/dispatch_stream_providers.dart';
import '../../theme/aduanext_theme.dart';

class LiveIndicator extends ConsumerWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dispatchStreamStateProvider).asData?.value ??
        StreamConnectionState.idle;

    final (label, fg, bg, border) = _visual(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: fg, pulsing: _pulsing(state)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color, Color) _visual(StreamConnectionState state) {
    switch (state) {
      case StreamConnectionState.live:
        return (
          'En vivo',
          AduaNextTheme.statusLevante,
          AduaNextTheme.statusLevanteBg,
          AduaNextTheme.stepperVerde,
        );
      case StreamConnectionState.connecting:
        return (
          'Conectando...',
          AduaNextTheme.statusValidando,
          AduaNextTheme.statusValidandoBg,
          AduaNextTheme.stepperAmarillo,
        );
      case StreamConnectionState.reconnecting:
        return (
          'Reconectando...',
          AduaNextTheme.statusValidando,
          AduaNextTheme.statusValidandoBg,
          AduaNextTheme.stepperAmarillo,
        );
      case StreamConnectionState.polling:
        return (
          'Polling 60s',
          AduaNextTheme.statusBorrador,
          AduaNextTheme.statusBorradorBg,
          AduaNextTheme.primary,
        );
      case StreamConnectionState.closed:
      case StreamConnectionState.idle:
        return (
          'Sin conexión',
          AduaNextTheme.textSecondary,
          AduaNextTheme.surfaceCard,
          AduaNextTheme.borderSubtle,
        );
    }
  }

  bool _pulsing(StreamConnectionState s) =>
      s == StreamConnectionState.connecting ||
      s == StreamConnectionState.reconnecting;
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool pulsing;
  const _Dot({required this.color, required this.pulsing});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.pulsing) _ac.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_ac.isAnimating) {
      _ac.repeat(reverse: true);
    } else if (!widget.pulsing && _ac.isAnimating) {
      _ac.stop();
      _ac.value = 1;
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, _) {
        // Pulse amplitude: 0.4 -> 1.0 when pulsing; fixed at 1.0 otherwise.
        final alpha = widget.pulsing ? 0.4 + (_ac.value * 0.6) : 1.0;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: alpha),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
