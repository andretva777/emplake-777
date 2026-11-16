import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';

enum SoundEffect { tap, success, error, whoosh }

/// Efeitos sonoros sintetizados em tempo de execução (sem arquivos de áudio).
/// Só tocam se o usuário ligar o som nas configurações.
class SoundService {
  SoundService(this._ref);

  final Ref _ref;
  static const int _sampleRate = 22050;

  final Map<SoundEffect, AudioPlayer> _players = {};
  final Map<SoundEffect, Uint8List> _cache = {};

  Future<void> play(SoundEffect effect) async {
    if (!_ref.read(settingsProvider).soundEnabled) return;
    try {
      final player = _players.putIfAbsent(effect, AudioPlayer.new);
      final bytes = _cache.putIfAbsent(effect, () => _build(effect));
      await player.stop();
      await player.play(
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: 0.6,
      );
    } catch (_) {
      // Se o áudio falhar, o jogo segue sem som.
    }
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
  }

  Uint8List _build(SoundEffect effect) => switch (effect) {
        SoundEffect.tap => _wav(_tone(660, 0.045)),
        SoundEffect.success => _wav([
            ..._tone(523.25, 0.09),
            ..._tone(659.25, 0.09),
            ..._tone(783.99, 0.09),
            ..._tone(1046.5, 0.22),
          ]),
        SoundEffect.error => _wav([
            ..._tone(207.65, 0.12, square: true),
            ..._tone(155.56, 0.2, square: true),
          ]),
        SoundEffect.whoosh => _wav(_sweep(900, 300, 0.22)),
      };

  /// Senoide (ou onda quadrada suavizada) com envelope para evitar estalos.
  List<double> _tone(double freq, double seconds, {bool square = false}) {
    final n = (seconds * _sampleRate).round();
    return List<double>.generate(n, (i) {
      final t = i / _sampleRate;
      var s = math.sin(2 * math.pi * freq * t);
      if (square) s = s.sign * 0.5 + s * 0.3;
      return s * _envelope(i, n);
    });
  }

  List<double> _sweep(double from, double to, double seconds) {
    final n = (seconds * _sampleRate).round();
    var phase = 0.0;
    return List<double>.generate(n, (i) {
      final f = from + (to - from) * (i / n);
      phase += 2 * math.pi * f / _sampleRate;
      return math.sin(phase) * _envelope(i, n) * 0.7;
    });
  }

  double _envelope(int i, int n) {
    final attack = math.min(1.0, i / (0.005 * _sampleRate));
    final release = math.min(1.0, (n - i) / (0.03 * _sampleRate));
    return math.min(attack, release);
  }

  /// Empacota amostras [-1, 1] como WAV PCM 16 bits mono.
  Uint8List _wav(List<double> samples) {
    final dataSize = samples.length * 2;
    final data = ByteData(44 + dataSize);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, _sampleRate, Endian.little);
    data.setUint32(28, _sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767 * 0.8).round();
      data.setInt16(44 + i * 2, v, Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService(ref);
  ref.onDispose(service.dispose);
  return service;
});
