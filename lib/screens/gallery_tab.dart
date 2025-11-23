import 'package:flutter/material.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  // 1. List of web image URLs
  // We use picsum.photos for random images.
  // The 'seed' ensures we get the same "random" image each time.
  final List<String> _webImages = const [
    'https://picsum.photos/seed/flutter_gallery_1/400/300',
    'https://picsum.photos/seed/flutter_gallery_2/400/300',
    'https://picsum.photos/seed/flutter_gallery_3/400/300',
  ];

  // 2. List of local asset paths
  // These MUST match the paths you defined in pubspec.yaml
  final List<String> _localImages = const [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    // Use ListView to make the content scrollable
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Section 1: Web Images ---
        _buildSectionTitle(context, 'From the Web'),
        const SizedBox(height: 12),
        _buildImageGrid(
          itemCount: _webImages.length,
          itemBuilder: (context, index) {
            return _buildWebImage(_webImages[index]);
          },
        ),

        const SizedBox(height: 24), // Spacer between sections
        // --- Section 2: Local Assets ---
        _buildSectionTitle(context, 'From Local Assets'),
        const SizedBox(height: 12),
        _buildImageGrid(
          itemCount: _localImages.length,
          itemBuilder: (context, index) {
            return _buildAssetImage(_localImages[index]);
          },
        ),
      ],
    );
  }

  // Helper widget for a styled section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Helper widget to build the responsive GridView
  Widget _buildImageGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return GridView.builder(
      // These two properties are crucial when nesting a GridView
      // inside a ListView (or SingleChildScrollView)
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 images per row
        crossAxisSpacing: 8, // Horizontal spacing
        mainAxisSpacing: 8, // Vertical spacing
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  // Helper widget for a styled web image with loading/error handling
  Widget _buildWebImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        // Best Practice: Show a loading spinner
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
        // Best Practice: Show an error icon if it fails
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
          );
        },
      ),
    );
  }

  // Helper widget for a styled asset image with error handling
  Widget _buildAssetImage(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        // Handle error if the asset path is wrong
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 40,
            ),
          );
        },
      ),
    );
  }
}
