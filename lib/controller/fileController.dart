import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

class FileController extends GetxController {
  var selectedFile = ''.obs;

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['pdf', 'png', 'jpg'],  // กำหนดชนิดไฟล์ที่อนุญาต
      type: FileType.custom,
    );

    if (result != null) {
      selectedFile.value = result.files.single.path ?? '';
    }
  }
}
