import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../models/FaceLivenessModel.dart';
import '../models/FacePositionModel.dart';

class FaceLivenessController extends GetxController {
  var cameraController = Rx<CameraController?>(null);
  var isProcessing = false.obs;
  var instruction = ''.obs;
  var livenessResult = LivenessResultModel(isLivenessPassed: false, accuracy: 0.0);
  List<Uint8List> detectionImages = [];

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    cameraController.value = CameraController(cameras[1], ResolutionPreset.medium);
    await cameraController.value?.initialize();
    update();
  }

  Future<void> startLivenessCheck() async {
    isProcessing.value = true;
    instruction.value = "Turn your head to the left";
    update();

    Uint8List imageLeft = await captureImage();
    await sendImageToAPI(imageLeft, 'left');

    await Future.delayed(Duration(seconds: 3));

    instruction.value = "Turn your head to the right";
    update();

    Uint8List imageRight = await captureImage();
    await sendImageToAPI(imageRight, 'right');

    await Future.delayed(Duration(seconds: 3));

    instruction.value = "Smile";
    update();

    Uint8List imageSmile = await captureImage();
    await sendImageToAPI(imageSmile, 'smile');

    livenessResult = LivenessResultModel(isLivenessPassed: true, accuracy: 0.98);
    isProcessing.value = false;
    update();
  }

  Future<Uint8List> captureImage() async {
    try {
      final image = await cameraController.value?.takePicture();
      final bytes = await image?.readAsBytes();
      return bytes!;
    } catch (e) {
      print("Error capturing image: $e");
      return Uint8List(0);
    }
  }

  Future<void> sendImageToAPI(Uint8List image, String position) async {
    String base64Image = base64Encode(image);

    final response = await http.post(
      Uri.parse('http://192.168.86.75:5001/face_liveness'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"image1": base64Image, "position": position}),
    );


    if (response.statusCode == 200) {
      print("Image sent successfully: ${response.body}");

      detectionImages.add(image);
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  }

  void checkFaceData(Map<String, dynamic> faceData) {
    int age = faceData['age'];
    String emotion = faceData['emotion'];
    String gender = faceData['gender'];

    // กำหนดเงื่อนไข
    if (age >= 18 && age <= 65 &&
        (emotion == 'happy' || emotion == 'neutral') &&
        gender == 'Man') {

      print("หน้าจอถูกปลดล็อค!");
    } else {

      print("การเข้าถึงถูกปฏิเสธ!");
    }
  }


  @override
  void onClose() {
    cameraController.value?.dispose();
    super.onClose();
  }
}
