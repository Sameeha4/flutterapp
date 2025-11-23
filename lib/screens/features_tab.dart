import 'dart:io'; // Required to work with File objects
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import the plugin

class FeaturesTab extends StatefulWidget {
  const FeaturesTab({super.key});

  @override
  State<FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends State<FeaturesTab> {
  // 1. Create state variables to hold the image files
  File? _galleryImageFile;
  File? _cameraImageFile;

  // 2. Create an instance of the ImagePicker
  final ImagePicker _picker = ImagePicker();

  // --- 3. Method to pick from Gallery ---
  Future<void> _pickFromGallery() async {
    try {
      // Pick an image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      // If an image is picked, update the state
      if (image != null) {
        setState(() {
          _galleryImageFile = File(image.path);
        });
      } else {
        // User cancelled the picker
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // --- 4. Method to take a picture with Camera ---
  Future<void> _takePicture() async {
    try {
      // Take a picture
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      // If a picture is taken, update the state
      if (image != null) {
        setState(() {
          _cameraImageFile = File(image.path);
        });
      } else {
        // User cancelled the camera
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take picture: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a ListView for a scrollable layout
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Card 1: Gallery Picker ---
        _buildFeatureCard(
          context: context,
          title: 'Gallery Image Picker',
          buttonText: 'Open Gallery',
          onPressed: _pickFromGallery,
          imageFile: _galleryImageFile,
          displayWidget: _galleryImageFile == null
              ? const Text(
                  'No image selected.',
                  style: TextStyle(color: Colors.grey),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    _galleryImageFile!,
                    width: 100, // As requested: 100x100
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 24),

        // --- Card 2: Camera Picker ---
        _buildFeatureCard(
          context: context,
          title: 'Camera Picture Taker',
          buttonText: 'Open Camera',
          onPressed: _takePicture,
          imageFile: _cameraImageFile,
          displayWidget: _cameraImageFile == null
              ? const Text(
                  'No picture taken.',
                  style: TextStyle(color: Colors.grey),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    _cameraImageFile!,
                    // Display this one larger
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
      ],
    );
  }

  // Helper widget to build a consistent card for each feature
  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String buttonText,
    required VoidCallback onPressed,
    required File? imageFile,
    required Widget displayWidget,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Image display area
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: displayWidget,
              ),
            ),
            const SizedBox(height: 16),

            // Action button
            ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
          ],
        ),
      ),
    );
  }
}