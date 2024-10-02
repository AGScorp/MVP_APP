import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../models/detectModel.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ComAndDetectController extends GetxController {
  var cameraController = Rx<CameraController?>(null);
  List<CameraDescription>? _cameras;
  bool _isLoading = false;
  FlutterVision? _flutterVision;
  var detectionList = <DetectionItem>[].obs;
  var isLoading = true.obs;
  File? image; // เก็บรูปที่เลือก
  final ImagePicker picker = ImagePicker(); // สร้างออบเจ็กต์ I
  var selectedImage;
  var similarityPercentage;
  Uint8List? croppedFaceImage;
  @override
  void onInit() {
    super.onInit();
    requestCameraPermission();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/yolov8n-face_float32.tflite",
      );
      print(res);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load model: $e');
    }
  }


  Future<void> calculate() async {
    if (detectionList.isEmpty || image == null) {
      Get.snackbar('Error', 'No images selected for comparison.');
      return;
    }

    List<double> similarityScores = []; // เก็บคะแนนความเหมือน

    for (var detection in detectionList) {
      double similarity = await detectFaceInImage(image!, detection);
      similarityScores.add(similarity);
      print('Comparing with: ${detection.label}, Similarity: ${similarity.toStringAsFixed(2)}%');
    }

    if (similarityScores.isNotEmpty) {
      double averageSimilarity = similarityScores.reduce((a, b) => a + b) / similarityScores.length;
      Get.snackbar('Success', 'Average Similarity: ${averageSimilarity.toStringAsFixed(2)}%');
    } else {
      Get.snackbar('Warning', 'No detections to compare.');
    }
  }

  Future<void> loadYoloModel() async {
    _flutterVision = FlutterVision();
    await _flutterVision?.loadYoloModel(
      modelPath: 'assets/yolov8n-face_float32.tflite',
      labels: 'assets/labels_Face.txt',
      numThreads: 1,
      useGpu: false,
      modelVersion: "yolov8",
    );
  }

  Future<double> detectFaceInImage(File image, DetectionItem detection) async {
    print("LOAD MODEL");

    // ตรวจสอบว่าโมเดลถูกโหลดหรือยัง
    if (_flutterVision == null) {
      await loadYoloModel(); // โหลดโมเดลถ้ายังไม่ได้โหลด
    }

    // อ่านภาพจากไฟล์
    img.Image? inputImage = img.decodeImage(await image.readAsBytes());
    if (inputImage == null) {
      Get.snackbar('Error', 'Failed to decode image.');
      return 0.0;
    }

    // ปรับขนาดภาพ
    img.Image resizedImage = img.copyResize(inputImage, width: 640, height: 640);
    Uint8List resizedImageBytes = img.encodeJpg(resizedImage); // หรือใช้ encodePng ตามต้องการ

    // รันโมเดลบนภาพ
    var recognitions = await _flutterVision?.yoloOnImage(
      bytesList: resizedImageBytes,
      imageHeight: 640, // กำหนดความสูงที่ปรับขนาดแล้ว
      imageWidth: 640,  // กำหนดความกว้างที่ปรับขนาดแล้ว
    );

    // ตรวจสอบการตรวจจับใบหน้า
    if (recognitions != null && recognitions.isNotEmpty) {
      double similarity = _calculateSimilarity(recognitions[0], detection);
      return similarity;
    }
print("Can't Detect");
    return 0.0; // ไม่มีการตรวจจับใบหน้า
  }



  double _calculateSimilarity(Map<String, dynamic> recognition, DetectionItem detection) {
    // คำนวณความเหมือนระหว่างใบหน้าที่ตรวจจับได้และ detection
    // สมมติว่ามีฟิลด์ confidence หรือ score ที่บอกคะแนนความเชื่อมั่น
    double confidence = recognition['confidence'] ?? 0.0; // รับคะแนนความเชื่อมั่นจาก recognition
    return confidence * 100; // คืนค่าความเหมือนในรูปแบบเปอร์เซ็นต์
  }


    double cosineSimilarity(List<double> vector1, List<double> vector2) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vector1.length; i++) {
      dotProduct += vector1[i] * vector2[i];
      normA += pow(vector1[i], 2).toDouble();
      normB += pow(vector2[i], 2).toDouble();
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    return dotProduct / (normA * normB);
  }
  // หลังจากที่คุณได้ภาพที่ถูกตรวจจับแล้ว เช่นในฟังก์ชัน runYoloFaceDetection หรือหลังจากได้ croppedFaceImage และ detectionImageData

  Future<void> processImagesAndCompare() async {
    // สมมติว่ามีการตรวจจับภาพเสร็จสิ้นและคุณมีทั้ง croppedFaceImage และ detectionImageData
    Uint8List? croppedFaceImage = this.croppedFaceImage;

    // ตรวจสอบว่า croppedFaceImage ไม่เป็น null ก่อนทำงาน
    if (croppedFaceImage == null) {
      print('No cropped face image available');
      return;
    }

    // ลูปผ่าน detectionList
    for (var detection in detectionList) {
      // เข้าถึง imageData ของแต่ละ detection
      Uint8List detectionImageData = detection.imageData;

      // ดึงคุณสมบัติจากข้อมูลภาพ
      List<double> detectionFeatures = await extractImageFeatures(detectionImageData);

      // ทำการเปรียบเทียบภาพภายในลูป
      final similarity = await compareFaces(croppedFaceImage, detectionImageData); // เรียกฟังก์ชันเปรียบเทียบภาพ
      if (similarity != null) {
        print('Similarity: $similarity%');

        // อัปเดตค่า similarity สำหรับแสดงผล
        // similarityPercentage = similarity;
        update(); // อัปเดต UI หลังจากได้ผลลัพธ์
      } else {
        print('Error calculating similarity');
      }
    }
  }


// ฟังก์ชันเปรียบเทียบภาพที่เลือกกับภาพใน detectionList
  Future<void> compareImagesWithDetectionList(Uint8List selectedImageBytes, List<DetectionItem> detectionList) async {
    // Extract features from the selected image
    List<double> selectedImageFeatures = await extractImageFeatures(selectedImageBytes);

    for (var detection in detectionList) {
      // Extract features from detection image
      List<double> detectionFeatures = await extractImageFeatures(detection.imageData); // Make sure imageData is a Uint8List

      // Calculate similarity
      double similarity = cosineSimilarity(selectedImageFeatures, detectionFeatures);
      detection.accuracy = similarity * 100; // Convert to percentage

      // Optional: Print or log the accuracy for debugging
      print("Detection ${detection.hashCode}: Accuracy = ${detection.accuracy}");
    }

    // Notify the UI to update
    update(); // Call this if you are using a state management solution like GetX
  }



  Future<List<double>> extractImageFeatures(Uint8List imageBytes) async {
    // Save the image bytes to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/temp_image.jpg';
    final file = File(tempPath);

    // Write the selected image bytes to the temporary file
    await file.writeAsBytes(imageBytes);

    // Run inference on the image
    var results = await Tflite.runModelOnImage(
      path: tempPath,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 128, // Depending on your model's output size
      threshold: 0.5,
    );

    // Extract features (assuming your model returns a list of doubles)
    if (results!.isNotEmpty) {
      return results[0]['embedding'].cast<double>(); // Adjust according to your model's output
    }
    return [];
  }


  Future<void> compareSelectedWithDetections() async {
    if (image != null) {
      // อ่านข้อมูลภาพที่เลือกจากผู้ใช้ (แปลง File เป็น Uint8List)
      Uint8List selectedImageBytes = await image!.readAsBytes();

      // เปรียบเทียบภาพที่เลือกกับภาพใน detectionList
      await compareImagesWithDetectionList(selectedImageBytes, detectionList);

      // อัปเดต UI หลังจากการเปรียบเทียบเสร็จสิ้น
      update();
    } else {
      print("No image selected for comparison");
    }
  }



  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();

    // เลือกภาพจากแกลเลอรี
    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);

    if (selectedImage != null) {
      image = File(selectedImage.path); // อัปเดตค่าภาพที่เลือก
      update(); // อัปเดต UI

      // เรียกใช้งาน YOLOv8 เพื่อตรวจจับใบหน้าในภาพที่เลือก
      Uint8List? croppedFaceImage = await runYoloFaceDetection(image!);
      if (croppedFaceImage != null) {
        this.croppedFaceImage = croppedFaceImage;
        update();
        print("Face detected and cropped.");
        // แสดงภาพที่ตัดบน UI หรือทำการจัดการอื่นๆ
      } else {
        print("No face detected.");
      }
    } else {
      print("No image selected");
    }
  }




  Future<void> compareImage(File capturedImage) async {
    if (capturedImage == null || selectedImage == null) {
      print("Either captured or selected image is missing");
      return;
    }

    // Load and process both images with YOLOv8
    Uint8List capturedImageData = await capturedImage.readAsBytes();
    img.Image? capturedImgDecoded = img.decodeImage(capturedImageData);

    Uint8List selectedImageData = await selectedImage.readAsBytes();
    img.Image? selectedImgDecoded = img.decodeImage(selectedImageData);

    if (capturedImgDecoded == null || selectedImgDecoded == null) {
      print("Error decoding one of the images.");
      return;
    }

    // YOLOv8 detection for captured image
    final capturedResults = await _flutterVision?.yoloOnImage(
      bytesList: capturedImageData,
      imageHeight: capturedImgDecoded.height,
      imageWidth: capturedImgDecoded.width,
      iouThreshold: 0.4,
      confThreshold: 0.5,
    );

    // YOLOv8 detection for selected image
    final selectedResults = await _flutterVision?.yoloOnImage(
      bytesList: selectedImageData,
      imageHeight: selectedImgDecoded.height,
      imageWidth: selectedImgDecoded.width,
      iouThreshold: 0.4,
      confThreshold: 0.5,
    );

    // Compare the detections (e.g., based on bounding boxes or tags)
    if (capturedResults != null && selectedResults != null) {
      double accuracy = compareResults(capturedResults, selectedResults);
      detectionList.add(
        DetectionItem(
          label: 'Comparison',
          imageData: capturedImageData,
          accuracy: accuracy,
        ),
      );
      update(); // Update UI to reflect the comparison result
    }
  }




  double compareResults(List<dynamic> capturedResults, List<dynamic> selectedResults) {
    // Logic to compare results between captured and selected images
    // This could involve comparing bounding boxes, tags, etc.
    // You can adjust this logic based on what you want to compare.

    int matches = 0;
    for (var captured in capturedResults) {
      for (var selected in selectedResults) {
        if (captured['tag'] == selected['tag']) {
          // Simple comparison by tag, can be more complex based on bounding box or other criteria
          matches++;
        }
      }
    }

    // Calculate accuracy as a percentage
    return (matches / selectedResults.length) * 100;
  }



  Future<Uint8List?> runYoloFaceDetection(File imageFile) async {
    Uint8List imageData = await imageFile.readAsBytes();
    img.Image? decodedImage = img.decodeImage(imageData);
    int imageHeight = decodedImage?.height ?? 0;
    int imageWidth = decodedImage?.width ?? 0;

    final faceResults = await _flutterVision?.yoloOnImage(
      bytesList: imageData,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      iouThreshold: 0.4,
      confThreshold: 0.5,
    );

    if (faceResults != null && faceResults.isNotEmpty) {
      for (var faceResult in faceResults) {
        final box = faceResult['box'];
        if (box != null && box is List && box.length == 5) {
          final xMin = box[0];
          final yMin = box[1];
          final xMax = box[2];
          final yMax = box[3];
          Uint8List? croppedFaceImage = await cropImageFromCapturedImage(imageData, xMin, yMin, xMax, yMax);
          return croppedFaceImage;
        }
      }
    }
    return null;
  }


  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
    if (await Permission.camera.isGranted) {
      await initializeCamera();
    } else {
      print("Camera permission denied");
    }
  }

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        throw Exception("No cameras available");
      }
      cameraController.value = CameraController(_cameras![0], ResolutionPreset.high);
      await cameraController.value?.initialize();

      _flutterVision = FlutterVision();
      await _flutterVision?.loadYoloModel(
        modelPath: 'assets/yolov5n.tflite',
        labels: 'assets/labels.txt',
        numThreads: 1,
        useGpu: false,
        modelVersion: "yolov5",
      );

      await _flutterVision?.loadYoloModel(
        modelPath: 'assets/yolov8n-face_float32.tflite',
        labels: 'assets/labels_Face.txt',
        numThreads: 1,
        useGpu: false,
        modelVersion: "yolov8",
      );

      isLoading.value = false;
      update();
    } catch (e) {
      print("Error initializing camera: $e");
      Get.snackbar("Error", "Failed to initialize camera.");
    }
  }



  Future<void> captureAndProcessImage() async {
    _isLoading = true; // Set loading state to true
    try {
      // Capture image
      XFile picture = await cameraController.value!.takePicture();
      Uint8List imageData = await picture.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageData);
      int imageHeight = decodedImage?.height ?? 0;
      int imageWidth = decodedImage?.width ?? 0;

      // Process the image with YOLOv5
      final results = await _flutterVision?.yoloOnImage(
        bytesList: imageData,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        iouThreshold: 0.4,
        confThreshold: 0.5,
      );

      bool personDetected = false;

      // Check for 'person' detection using YOLOv5
      if (results != null && results.isNotEmpty) {
        for (var result in results) {
          final tag = result['tag'];
          if (tag == 'person') {
            personDetected = true;
            break;
          }
        }
      }

      // If no person is detected by YOLOv5, use YOLOv8 for detection
      if (!personDetected) {
        final faceResults = await _flutterVision?.yoloOnImage(
          bytesList: imageData,
          imageHeight: imageHeight,
          imageWidth: imageWidth,
          iouThreshold: 0.4,
          confThreshold: 0.5,
        );

        if (faceResults != null && faceResults.isNotEmpty) {
          // Clear previous detections before processing new ones
          detectionList.clear();

          // Process detected faces
          for (var faceResult in faceResults) {
            final box = faceResult['box'];
            final tag = faceResult['tag'];
            if (box != null && box is List && box.length == 5) {
              final xMin = box[0];
              final yMin = box[1];
              final xMax = box[2];
              final yMax = box[3];

              // Crop the image based on detected bounding box for face
              Uint8List? croppedFaceImage = await cropImageFromCapturedImage(imageData, xMin, yMin, xMax, yMax);
              if (croppedFaceImage != null) {
                detectionList.add(
                  DetectionItem(label: tag, imageData: croppedFaceImage),
                );
              }
            }
          }
        }
      } else {
        // If person is detected, process the image with YOLOv8 for face detection
        final faceResults = await _flutterVision?.yoloOnImage(
          bytesList: imageData,
          imageHeight: imageHeight,
          imageWidth: imageWidth,
          iouThreshold: 0.4,
          confThreshold: 0.5,
        );

        if (faceResults != null && faceResults.isNotEmpty) {
          // Clear previous detections before processing new ones
          detectionList.clear();

          // Process detected faces
          for (var faceResult in faceResults) {
            final box = faceResult['box'];
            final tag = faceResult['tag'];
            if (box != null && box is List && box.length == 5) {
              final xMin = box[0];
              final yMin = box[1];
              final xMax = box[2];
              final yMax = box[3];

              // Crop the image based on detected bounding box for face
              Uint8List? croppedFaceImage = await cropImageFromCapturedImage(imageData, xMin, yMin, xMax, yMax);
              if (croppedFaceImage != null) {
                detectionList.add(
                  DetectionItem(label: tag, imageData: croppedFaceImage),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error in capturing and processing image: $e");
    } finally {
      _isLoading = false; // Reset loading state
      update();
    }
  }

  Future<double?> compareFaces(Uint8List image1, Uint8List image2) async {
    // เช็คการเชื่อมต่อ
    if (image1.isEmpty || image2.isEmpty) {
      print('Error: One or both images are empty');
      return null;
    }

    // แปลง Uint8List เป็น Base64 string
    String base64Image1 = base64Encode(image1);
    String base64Image2 = base64Encode(image2);

    final response = await http.post(
      Uri.parse('http://192.168.86.75:5001/compare_faces'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "image1": base64Image1,
        "image2": base64Image2,
      }),
    );

    print(response.body);

    try {
      // ตรวจสอบสถานะการตอบกลับจากเซิร์ฟเวอร์
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        for (var detection in detectionList) {
          // Extract features from detection image
          detection.accuracy = result['score'] ?? 0.0;
print(result['score']);
          // Optional: Print or log the accuracy for debugging
          print("Detection ${detection.hashCode}: Accuracy = ${detection.accuracy}");
        }
        // อัปเดตค่าของ detection.accuracy


        // อัปเดต UI
        update();

        return result['similarity'];
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // แสดงข้อผิดพลาดที่เกิดขึ้น
      print('Error: $e');
      return null;
    }
  }

  Future<Uint8List?> cropImageFromCapturedImage(Uint8List imageData, double xMin, double yMin, double xMax, double yMax) async {
    try {
      img.Image? originalImage = img.decodeImage(imageData);
      if (originalImage != null) {
        int cropX = xMin.toInt();
        int cropY = yMin.toInt();
        int cropWidth = (xMax - xMin).toInt();
        int cropHeight = (yMax - yMin).toInt();

        cropX = cropX.clamp(0, originalImage.width - 1);
        cropY = cropY.clamp(0, originalImage.height - 1);
        cropWidth = cropWidth.clamp(0, originalImage.width - cropX);
        cropHeight = cropHeight.clamp(0, originalImage.height - cropY);

        img.Image cropped = img.copyCrop(originalImage, x: cropX, y: cropY, width: cropWidth, height: cropHeight);
        Uint8List pngBytes = Uint8List.fromList(img.encodePng(cropped));
        return pngBytes;
      }
    } catch (e) {
      print("Error in cropping image: $e");
    }
    return null;
  }
}
