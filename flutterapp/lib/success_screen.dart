import 'dart:typed_data';
import 'dart:convert'; // Add this import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class SuccessScreen extends StatelessWidget {
  final String imagePath;
  final Uint8List? imageBytes;
  final File? imageFile;
  final Map<String, dynamic>? predictionResult;

  const SuccessScreen({
    super.key,
    required this.imagePath,
    this.imageBytes,
    this.imageFile,
    this.predictionResult,
  });

  Uint8List? _getProcessedImage() {
    if (predictionResult != null && 
        predictionResult!['preprocessed_image_base64'] != null) {
      return base64Decode(predictionResult!['preprocessed_image_base64']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final processedImageBytes = _getProcessedImage();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prediction Results',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BounceInDown(
                duration: const Duration(milliseconds: 1000),
                child: Text(
                  predictionResult != null 
                      ? 'Prediction Successful!' 
                      : 'Image Uploaded!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              
              if (predictionResult != null) ...[
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Prediction Details',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            'Class:',
                            predictionResult!['predicted_class'],
                            Icons.category,
                          ),
                          _buildInfoRow(
                            'Confidence:',
                            '${(predictionResult!['confidence'] * 100).toStringAsFixed(2)}%',
                            Icons.assessment,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Meaning:',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            predictionResult!['meaning'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
              
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          processedImageBytes != null 
                              ? 'Processed Image' 
                              : 'Original Image',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: processedImageBytes != null
                            ? Image.memory(
                                processedImageBytes,
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (kIsWeb
                                ? Image.memory(
                                    imageBytes!,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    imageFile!,
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              ZoomIn(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    label: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}