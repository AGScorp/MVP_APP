import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechController extends GetxController {
  var isListening = false.obs;
  var text = "Press the button and start speaking".obs;

  stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void onInit() {
    super.onInit();
    checkSpeechRecognitionAvailability(); // เช็คความสามารถการรู้จำเสียงเมื่อเริ่ม
  }

  Future<void> listen() async {
    // ตรวจสอบและขอ Permission สำหรับไมโครโฟน
    if (await _requestMicrophonePermission()) {
      // เริ่มการฟังเสียงถ้า permission ถูกต้อง
      if (!isListening.value) {
        await _initializeSpeechRecognition();
      } else {
        isListening.value = false;
        _speech.stop();
      }
    } else {
      print("Microphone permission is denied.");
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      isListening.value = true;
      _speech.listen(onResult: (val) {
        text.value = val.recognizedWords;
      });
    } else {
      print("Speech recognition not available on this device.");
      isListening.value = false;
    }
  }

  Future<void> checkSpeechRecognitionAvailability() async {
    bool available = await _speech.initialize();
    if (!available) {
      print("Speech recognition not available on this device.");
    } else {
      print("Speech recognition is available.");
    }
  }
}
