
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/fileController.dart';

class FilePickerPage extends StatefulWidget {
  const FilePickerPage({super.key});

  @override
  State<FilePickerPage> createState() => _FilePickerPageState();
}

class _FilePickerPageState extends State<FilePickerPage> {
  final FileController fileController = Get.put(FileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLOv10X Model Service'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Obx(() => Text(
              fileController.selectedFile.isEmpty
                  ? 'No file selected'
                  : 'Selected: ${fileController.selectedFile}',
            )),
            ElevatedButton(
              onPressed: () {
                fileController.pickFile();
              },
              child: const Text('Pick File'),
            ),
            ElevatedButton(
              onPressed: () {
                // Add logic to process the file with YOLOv10X model
              },
              child: const Text('Process File'),
            ),
          ],
        ),
      ),
    );
  }
}
