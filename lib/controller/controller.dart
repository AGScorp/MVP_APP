import 'package:get/get.dart';
// Controller class for GetX
class CounterController extends GetxController {
  // Define a reactive variable using RxInt
  var counter = 0.obs;

  void increment() {
    counter++;
  }
}