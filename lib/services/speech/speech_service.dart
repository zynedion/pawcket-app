import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (val) => print('SpeechToText Error: $val'),
        onStatus: (val) => print('SpeechToText Status: $val'),
      );
      return _isInitialized;
    } catch (e) {
      print('SpeechToText initialization failed: $e');
      return false;
    }
  }

  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onTimeout,
  }) async {
    final initialized = await initialize();
    if (!initialized) {
      throw Exception('Speech service not initialized');
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: 'id_ID',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }
}
