import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Image Uploader',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: const UploadScreen(),
  );
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  XFile? _image;
  double _progress = 0;
  String? _remoteUrl;
  String _statusMessage = '';
  String? _meaning;

  Future<void> _pick() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _image = img;
        _statusMessage = '';
        _remoteUrl = null;
        _meaning = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_image == null) return;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        _image!.path,
        filename: _image!.name,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    setState(() {
      _statusMessage = 'Uploading...';
      _progress = 0;
    });

    try {
      final res = await _dio.post(
        '/upload-image',
        data: formData,
        onSendProgress: (sent, total) =>
            setState(() => _progress = sent / total),
      );
      setState(() {
        _remoteUrl = res.data['url'] as String?;
        _meaning = res.data['meaning'] ?? 'No meaning found';
        _statusMessage = 'Upload successful!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload failed: $e';
      });
    } finally {
      setState(() => _progress = 0);
    }
  }

  void _reset() {
    setState(() {
      _image = null;
      _remoteUrl = null;
      _meaning = null;
      _progress = 0;
      _statusMessage = '';
    });
  }

  void _openImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Full Image")),
          body: Center(child: Image.network(imageUrl)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Upload Image to Show Meaning'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_image != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _remoteUrl != null
                          ? () => _openImageFullscreen(
                              context,
                              'http://10.0.2.2:8000$_remoteUrl',
                            )
                          : null,
                      child: Image.file(File(_image!.path), height: 200),
                    ),
                    const SizedBox(height: 10),
                    if (_progress > 0)
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[200],
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pick Image from Gallery'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _upload,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Upload to Server'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (_statusMessage.isNotEmpty)
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains('successful')
                    ? Colors.green
                    : _statusMessage.contains('failed')
                    ? Colors.red
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (_remoteUrl != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              'Uploaded URL: http://10.0.2.2:8000$_remoteUrl',
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
            ),
          ],
          if (_meaning != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meaning:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(_meaning!, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
