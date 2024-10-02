import 'package:get/get.dart';
import 'package:mvp_app/controller/fileController.dart';
import 'controller/CameraController.dart';
import 'controller/YoloController.dart';
import 'controller/controller.dart';


class CounterBinding extends Bindings {
  @override
  void dependencies() {
    // Bind the CounterController when this binding is used
    Get.lazyPut<CounterController>(() => CounterController());
    Get.lazyPut<FileController>(() => FileController());
    Get.lazyPut<CameraAIController>(() => CameraAIController());
  }
}
