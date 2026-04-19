import 'dart:io';

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

enum MediaType { none, image, video }

class MediaPickerWidget extends StatelessWidget {
  final File? selectedMedia;
  final String? existingImageUrl;
  final String? existingVideoUrl;
  final MediaType mediaType;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onRemove;

  const MediaPickerWidget({
    super.key,
    this.selectedMedia,
    this.existingImageUrl,
    this.existingVideoUrl,
    required this.mediaType,
    required this.isUploading,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onRemove,
  });

  bool get _hasMedia =>
      selectedMedia != null ||
      (existingImageUrl != null && existingImageUrl!.isNotEmpty) ||
      (existingVideoUrl != null && existingVideoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media di copertina',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _hasMedia ? _buildMediaPreview(context) : _buildEmptyState(context),
        ),
        const SizedBox(height: 4),
        Text(
          'Lascia vuoto per usare un colore casuale',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: mediaType == MediaType.video
              ? _buildVideoPlaceholder()
              : _buildImagePreview(),
        ),
        if (isUploading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                color: Colors.black.withValues(alpha: 0.6),
                onPressed: () => _showMediaPickerDialog(context),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete,
                color: Colors.red.withValues(alpha: 0.8),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, size: 64, color: Colors.white70),
          SizedBox(height: 8),
          Text(
            'Video selezionato',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (selectedMedia != null) {
      return Image.file(
        selectedMedia!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.network(
      existingImageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return InkWell(
      onTap: () => _showMediaPickerDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
              const SizedBox(width: 16),
              Icon(Icons.videocam_outlined, size: 40, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tocca per aggiungere immagine o video',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showMediaPickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleziona tipo di media',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Color(0xFF2C2942)),
                ),
                title: const Text('Immagine'),
                subtitle: const Text('Seleziona dalla galleria'),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam, color: Color(0xFF2C2942)),
                ),
                title: const Text('Video'),
                subtitle: const Text('Max 2 minuti'),
                onTap: () {
                  Navigator.pop(context);
                  onPickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
