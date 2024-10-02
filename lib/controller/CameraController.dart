import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import '../models/detectModel.dart';

class CameraAIController extends GetxController {
  var cameraController = Rx<CameraController?>(null);
  List<CameraDescription>? _cameras;
  bool _isLoading = false;
  FlutterVision? _flutterVision;
  var detectionList = <DetectionItem>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    requestCameraPermission();
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

      isLoading.value = false;
      update();
    } catch (e) {
      print("Error initializing camera: $e");
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
      // Process the image with YOLO
      final results = await _flutterVision?.yoloOnImage(
        bytesList: imageData,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        iouThreshold: 0.4,
        confThreshold: 0.5,
      );

      if (results != null && results.isNotEmpty) {
        // Process detected items
        for (var result in results) {
          final box = result['box'];
          final tag = result['tag'];
          if (box != null && box is List && box.length == 5) {
            final xMin = box[0];
            final yMin = box[1];
            final xMax = box[2];
            final yMax = box[3];

            // Crop the image based on detected bounding box
            Uint8List? croppedImage = await cropImageFromCapturedImage(imageData, xMin, yMin, xMax, yMax);
            if (croppedImage != null) {
              detectionList.add(
                DetectionItem(label: tag, imageData: croppedImage),
              );
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

// Existing cropImageFromCapturedImage method remains unchanged...
}
