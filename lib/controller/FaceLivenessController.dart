import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../models/FaceLivenessModel.dart';
import '../models/FacePositionModel.dart';
import 'package:googleapis/texttospeech/v1.dart';
// import 'package:googleapis_auth/auth_io.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';


class FaceLivenessController extends GetxController {
  var cameraController = Rx<CameraController?>(null);
  var isProcessing = false.obs;
  var instruction = ''.obs;
  var livenessResult = LivenessResultModel(isLivenessPassed: false, accuracy: 0.0);
  List<Uint8List> detectionImages = [];
  FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  late FaceDetection expectedFaceDetection;
  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }


  Future<void> playAudio(filename) async {
    try{
      await audioPlayer.play(AssetSource('$filename'));
    }catch(e){
      print(e);
    }
  }


  Future _speak(String text) async {
    FlutterTts flutterTts = FlutterTts();
    var languages = await flutterTts.getLanguages;
    print("Supported languages: $languages");


    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);

  }


  // Future<void> speakWithGoogleTTS(String text) async {
  //   var client = await clientViaApiKey('YOUR_API_KEY');
  //
  //   var tts = TexttospeechApi(client);
  //   var request = SynthesizeSpeechRequest.fromJson({
  //     'input': {'text': text},
  //     'voice': {'languageCode': 'th-TH', 'name': 'th-TH-Wavenet-A'},
  //     'audioConfig': {'audioEncoding': 'MP3'},
  //   });
  //
  //   var response = await tts.text.synthesize(request);
  //
  //   // Save the audio output
  //   var file = File('output.mp3');
  //   await file.writeAsBytes(response.audioContentAsBytes);
  //   print('Audio content written to file "output.mp3"');
  // }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    cameraController.value = CameraController(cameras[1], ResolutionPreset.medium);
    await cameraController.value?.initialize();
    update();
  }

  Future<void> startLivenessCheck() async {
    isProcessing.value = true;

    await Future.delayed(Duration(seconds: 2));
    playAudio('left.mp3');
    instruction.value = "Turn your head to the left";

    // instruction.value = "หันหัวไปทางซ้าย";
    update();

    Uint8List imageLeft = await captureImage();

    await sendImageToAPI(imageLeft, 'left');
    // _speak(instruction.value);


    await Future.delayed(Duration(seconds: 6));

    playAudio('right.mp3');
    await Future.delayed(Duration(seconds: 2));
    instruction.value = "Turn your head to the right";
    // instruction.value = "หันหัวไปทางขวา";



    update();

    Uint8List imageRight = await captureImage();


    await sendImageToAPI(imageRight, 'right');

    await Future.delayed(Duration(seconds: 6));
    playAudio('smile.mp3');

    instruction.value = "Smile";
    await Future.delayed(Duration(seconds: 2));
    // instruction.value = "ไหนลองยิ้มสิ้";
    // _speak(instruction.value);
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
    try {
      final response = await http.post(
        Uri.parse('https://28ae-182-52-131-69.ngrok-free.app/face_liveness'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image1": base64Image, "position": position}),
      );

      if (response.statusCode == 200) {
        print("Image sent successfully: ${response.body}");

        Map<String, dynamic> responseJson = jsonDecode(response.body);
        print("Response JSON: $responseJson");

        // Parse the JSON response
        FaceDetection faceDetection = FaceDetection.fromJson(responseJson);

        // Use the faceDetection object for further processing
        print("Gender: ${faceDetection.gender}");
        print("Face Position: ${faceDetection.facePosition}");

        detectionImages.add(image);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    }catch(e){

      print(e);
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



  Future<void> sendImageToUnlock(BuildContext context) async {
    Uint8List imageLeft = await captureImage();
    String base64Image = base64Encode(imageLeft);

    try {
      final response = await http.post(
        Uri.parse('https://28ae-182-52-131-69.ngrok-free.app/face_liveness'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image1": base64Image}),
      );

      if (response.statusCode == 200) {
        // print("Image sent successfully: ${response.body}");

        Map<String, dynamic> responseJson = jsonDecode(response.body);
        print("Response JSON: $responseJson");

        // Extract the face position and gender from the response
        List<dynamic> data = responseJson['data']; // Access the data array
        if (data.isNotEmpty && data[0].isNotEmpty) {
          Map<String, dynamic> faceDetectionData = data[0][0]; // Access the first face detection item
          Map<String, dynamic> facePositionJson = faceDetectionData['face_position']; // Now access face_position
          double h = facePositionJson['h'] ?? 0.0;

          // Compare with expected values
          if (expectedFaceDetection.facePosition.h == h) {
            String gender = faceDetectionData['gender'] ?? '';

            // Check the gender
            if (gender == expectedFaceDetection.gender) {
              _showUnlockSnackbar(context);
            }
          }
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print(e);
    }
  }




// Function to show Snackbar
  void _showUnlockSnackbar(BuildContext context) {
    final snackBar = SnackBar(
      content: Text('Unlock'),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }




  @override
  void onClose() {
    cameraController.value?.dispose();
    super.onClose();
  }
}
