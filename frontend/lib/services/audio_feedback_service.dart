import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioFeedbackService {
  AudioFeedbackService()
    : _tts = FlutterTts(),
      _dangerPlayer = AudioPlayer(),
      _arrivalPlayer = AudioPlayer(),
      _waypointPlayer = AudioPlayer() {
    _dangerPlayer.setReleaseMode(ReleaseMode.stop);
    _arrivalPlayer.setReleaseMode(ReleaseMode.stop);
    _waypointPlayer.setReleaseMode(ReleaseMode.stop);
  }

  final FlutterTts _tts;
  final AudioPlayer _dangerPlayer;
  final AudioPlayer _arrivalPlayer;
  final AudioPlayer _waypointPlayer;

  bool _ttsInitialized = false;

  Future<void> speakNavigation(String message) async {
    await _speak(message, stopFirst: true);
  }

  Future<void> playDangerAlertWithSpeech(String message) async {
    await _playAsset(
      player: _dangerPlayer,
      assetPath: 'audio/danger_alert.wav',
    );
    await _speak(message, stopFirst: true);
  }

  Future<void> playArrivalCue(String message) async {
    await _playAsset(
      player: _arrivalPlayer,
      assetPath: 'audio/arrival_chime.wav',
    );
    await _speak(message, stopFirst: true);
  }

  Future<void> playWaypointCue() async {
    await _playAsset(
      player: _waypointPlayer,
      assetPath: 'audio/arrival_chime.wav',
    );
  }

  Future<void> stopSpeech() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore platform-level TTS stop failures.
    }
  }

  Future<void> dispose() async {
    await stopSpeech();
    try {
      await _dangerPlayer.dispose();
      await _arrivalPlayer.dispose();
      await _waypointPlayer.dispose();
    } catch (_) {
      // Dispose defensively for plugin-backed resources.
    }
  }

  Future<void> _ensureTtsInitialized() async {
    if (_ttsInitialized) {
      return;
    }

    _ttsInitialized = true;
    try {
      await _tts.setSharedInstance(true);
    } catch (_) {
      // Unsupported on some platforms.
    }

    try {
      await _tts.setLanguage('es-ES');
    } catch (_) {
      try {
        await _tts.setLanguage('es');
      } catch (_) {
        // Fall back to the platform default voice.
      }
    }

    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      // Keep defaults when a platform does not expose a setting.
    }
  }

  Future<void> _speak(String message, {required bool stopFirst}) async {
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return;
    }

    try {
      await _ensureTtsInitialized();
      if (stopFirst) {
        await _tts.stop();
      }
      await _tts.speak(normalizedMessage);
    } catch (error) {
      debugPrint('AudioFeedbackService.speak failed: $error');
    }
  }

  Future<void> _playAsset({
    required AudioPlayer player,
    required String assetPath,
  }) async {
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (error) {
      debugPrint('AudioFeedbackService.playAsset failed: $error');
    }
  }
}
