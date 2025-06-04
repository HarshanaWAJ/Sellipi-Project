import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ImageSnap/success_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class CaptureImageScreen extends StatefulWidget {
  const CaptureImageScreen({super.key});

  @override
  State<CaptureImageScreen> createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen> {
  File? _image;

  Future<void> _captureImage() async {
    // Store the ScaffoldMessenger state before the async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final status = await Permission.camera.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  void _resetImage() {
    setState(() {
      _image = null;
    });
  }

  void _uploadImage() {
    if (_image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(imagePath: _image!.path),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture an image first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Image')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: _image == null
                  ? const Center(child: Text('No image captured'))
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text('Capture Image'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _uploadImage,
                  child: const Text('Upload'),
                ),
                ElevatedButton(
                  onPressed: _resetImage,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
