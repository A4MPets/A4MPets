import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_feedback_service.dart';

final audioFeedbackServiceProvider = Provider<AudioFeedbackService>((ref) {
  final AudioFeedbackService service = AudioFeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
