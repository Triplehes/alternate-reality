import 'package:speech_to_text/speech_to_text.dart';

abstract interface class SpeechService {
  Future<bool> initialize();
  Future<void> startListening(void Function(String) onText);
  Future<void> stopListening();
  Future<void> cancelListening();
  bool get isAvailable;
}

class DeviceSpeechService implements SpeechService {
  DeviceSpeechService({SpeechToText? speech, this.onFinished})
    : speech = speech ?? SpeechToText();
  final SpeechToText speech;
  final void Function()? onFinished;
  bool available = false;
  @override
  bool get isAvailable => available;
  @override
  Future<bool> initialize() async => available = await speech.initialize(
    onStatus: (status) {
      if (status == 'done' || status == 'notListening') onFinished?.call();
    },
    onError: (_) => onFinished?.call(),
  );
  @override
  Future<void> startListening(void Function(String) onText) => speech.listen(
    onResult: (r) => onText(r.recognizedWords),
    listenOptions: SpeechListenOptions(
      partialResults: true,
      cancelOnError: true,
    ),
  );
  @override
  Future<void> stopListening() => speech.stop();
  @override
  Future<void> cancelListening() => speech.cancel();
}
