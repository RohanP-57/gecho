import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageService {
  // Cloudinary configuration from environment variables
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  
  late final CloudinaryPublic _cloudinary;
  
  ImageService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }
  
  // Upload image to Cloudinary
  Future<String?> uploadImage({
    required File imageFile,
    required String userId,
    required String postId,
    required String folder,
  }) async {
    try {
      // Create a unique public ID for the image
      final publicId = '${folder}/${userId}_${postId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload to Cloudinary
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          publicId: publicId,
          folder: folder,
        ),
      );
      
      // Return the secure URL
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  // Delete image from Cloudinary
  // Note: Client-side deletion is not supported by cloudinary_public package
  // Images can be deleted from Cloudinary admin panel or via server-side API
  Future<void> deleteImage(String publicId) async {
    try {
      // For now, we'll just log the deletion request
      // In production, you might want to call a backend API to handle deletion
      print('Image deletion requested for: $publicId');
      print('Note: Client-side deletion not supported. Remove from Cloudinary admin panel if needed.');
    } catch (e) {
      print('Error processing image deletion: $e');
      rethrow;
    }
  }
  
  // Extract public ID from Cloudinary URL
  String? extractPublicIdFromUrl(String imageUrl) {
    try {
      // Cloudinary URLs have format: https://res.cloudinary.com/{cloud_name}/image/upload/{transformations}/{public_id}.{format}
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the upload segment and get everything after it
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        // Join all segments after 'upload' and remove file extension
        final publicIdWithExtension = pathSegments.sublist(uploadIndex + 1).join('/');
        final lastDotIndex = publicIdWithExtension.lastIndexOf('.');
        if (lastDotIndex != -1) {
          return publicIdWithExtension.substring(0, lastDotIndex);
        }
        return publicIdWithExtension;
      }
      return null;
    } catch (e) {
      print('Error extracting public ID from URL: $e');
      return null;
    }
  }
  
  // Generate optimized image URL with transformations
  String getOptimizedImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      final publicId = extractPublicIdFromUrl(originalUrl);
      if (publicId == null) return originalUrl;
      
      List<String> transformations = [];
      
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');
      
      final transformationString = transformations.join(',');
      
      return 'https://res.cloudinary.com/$_cloudName/image/upload/$transformationString/$publicId';
    } catch (e) {
      print('Error generating optimized URL: $e');
      return originalUrl;
    }
  }
}