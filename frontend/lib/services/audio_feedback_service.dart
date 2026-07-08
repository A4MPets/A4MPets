import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class AudioFeedbackService {
  static const MethodChannel _audioBackgroundChannel = MethodChannel('com.a4mpets/audio_background_service');

  AudioFeedbackService()
    : _tts = FlutterTts(),
      _dangerPlayer = AudioPlayer(),
      _arrivalPlayer = AudioPlayer(),
      _waypointPlayer = AudioPlayer() {
    _dangerPlayer.setReleaseMode(ReleaseMode.stop);
    _arrivalPlayer.setReleaseMode(ReleaseMode.stop);
    _waypointPlayer.setReleaseMode(ReleaseMode.stop);
    unawaited(_configureAudioContext());
  }

  final FlutterTts _tts;
  final AudioPlayer _dangerPlayer;
  final AudioPlayer _arrivalPlayer;
  final AudioPlayer _waypointPlayer;

  bool _ttsInitialized = false;
  bool _isSpeaking = false;
  bool _backgroundAudioRequested = false;
  final List<String> _speechQueue = <String>[];
  Completer<void>? _speechCompleter;

  Future<void> enableBackgroundAudio({String? notificationText}) async {
    if (_backgroundAudioRequested) {
      if (notificationText != null && notificationText.trim().isNotEmpty)
        await _updateBackgroundAudioNotification(notificationText.trim());
      return;
    }
    _backgroundAudioRequested = true;
    await _startBackgroundAudioService(notificationText: notificationText);
  }

  Future<void> disableBackgroundAudio() async {
    _backgroundAudioRequested = false;
    await _stopBackgroundAudioService();
  }

  Future<void> speakNavigation(String message) async {
    await _enqueueSpeech(message, clearQueue: true, stopCurrent: false);
  }

  Future<void> playDangerAlertWithSpeech(String message) async {
    await _playAsset(player: _dangerPlayer, assetPath: 'audio/danger_alert.wav');
    await _enqueueSpeech(message, clearQueue: true, stopCurrent: true);
  }

  Future<void> playArrivalCue(String message) async {
    await _playAsset(player: _arrivalPlayer, assetPath: 'audio/arrival_chime.wav');
    await _enqueueSpeech(message, clearQueue: true, stopCurrent: true);
  }

  Future<void> playWaypointCue() async {
    await _playAsset(player: _waypointPlayer, assetPath: 'audio/arrival_chime.wav');
  }

  Future<void> stopSpeech() async {
    try {
      debugPrint('AudioFeedbackService: Stopping speech');
      _speechQueue.clear();
      await _tts.stop();
    } catch (_) {
      // Ignore platform-level TTS stop failures.
    } finally {
      _isSpeaking = false;
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) _speechCompleter!.complete();
    }
  }

  Future<void> dispose() async {
    await disableBackgroundAudio();
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
    if (_ttsInitialized) return;

    _ttsInitialized = true;
    try {
      await _tts.setSharedInstance(true);
    } catch (_) {
      // Unsupported on some platforms.
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ], IosTextToSpeechAudioMode.voicePrompt);
      } catch (_) {
        // Keep defaults when iOS category configuration is unavailable.
      }
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

    _tts.setCompletionHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) _speechCompleter!.complete();
    });

    _tts.setErrorHandler((dynamic message) {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) _speechCompleter!.complete();
    });

    _tts.setCancelHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) _speechCompleter!.complete();
    });
  }

  Future<void> _configureAudioContext() async {
    try {
      final AudioContext context = AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.assistanceNavigationGuidance,
          contentType: AndroidContentType.speech,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.allowBluetoothA2DP,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );
      await _dangerPlayer.setAudioContext(context);
      await _arrivalPlayer.setAudioContext(context);
      await _waypointPlayer.setAudioContext(context);
    } catch (_) {
      // Keep player defaults if a platform does not support custom contexts.
    }
  }

  Future<void> _startBackgroundAudioService({String? notificationText}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _audioBackgroundChannel.invokeMethod<void>('startAudioBackgroundService', <String, dynamic>{
        'notificationText': notificationText?.trim(),
      });
    } catch (error) {
      debugPrint('AudioFeedbackService.startBackgroundService failed: $error');
    }
  }

  Future<void> _updateBackgroundAudioNotification(String text) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _audioBackgroundChannel.invokeMethod<void>('updateAudioBackgroundNotification', <String, dynamic>{
        'notificationText': text,
      });
    } catch (error) {
      debugPrint('AudioFeedbackService.updateNotification failed: $error');
    }
  }

  Future<void> _stopBackgroundAudioService() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _audioBackgroundChannel.invokeMethod<void>('stopAudioBackgroundService');
    } catch (error) {
      debugPrint('AudioFeedbackService.stopBackgroundService failed: $error');
    }
  }

  Future<void> _enqueueSpeech(String message, {required bool clearQueue, required bool stopCurrent}) async {
    final String normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;

    if (clearQueue) _speechQueue.clear();

    if (stopCurrent) await stopSpeech();

    _speechQueue.add(normalizedMessage);
    unawaited(_processSpeechQueue());
  }

  Future<void> _processSpeechQueue() async {
    if (_isSpeaking) return;
    _isSpeaking = true;

    try {
      await _ensureTtsInitialized();
      while (_speechQueue.isNotEmpty) {
        if (!_isSpeaking) break;
        final String nextMessage = _speechQueue.removeAt(0);

        _speechCompleter = Completer<void>();
        await _tts.speak(nextMessage);

        if (_speechCompleter != null) await _speechCompleter!.future;
        _speechCompleter = null;
      }
    } catch (error) {
      debugPrint('AudioFeedbackService.processQueue failed: $error');
    } finally {
      _isSpeaking = false;
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) _speechCompleter!.complete();
      _speechCompleter = null;
    }
  }

  Future<void> _playAsset({required AudioPlayer player, required String assetPath}) async {
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (error) {
      debugPrint('AudioFeedbackService.playAsset failed: $error');
    }
  }
}
