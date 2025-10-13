import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ImageService {
  static const String _cloudName = 'dskglf2tn'; // Replace with your actual cloud name
  static const String _apiKey = '964545945632381';
  static const String _apiSecret = 'w-7cFQHNiVF87eyU6Zmu5uk9Lo4'; // Replace with your actual API secret
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Upload image to Cloudinary
  Future<String?> uploadImage({
    required File imageFile,
    required String userId,
    required String postId,
    String folder = 'posts',
  }) async {
    try {
      print('Starting Cloudinary upload...');
      print('File path: ${imageFile.path}');
      print('File size: ${getFileSizeInMB(imageFile).toStringAsFixed(2)} MB');
      
      // Validate file
      if (!isValidImageFile(imageFile)) {
        print('Invalid image file type');
        return null;
      }
      
      if (!isFileSizeAcceptable(imageFile)) {
        print('File size too large');
        return null;
      }
      
      // Generate timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Create public_id for the image
      final publicId = '$folder/$userId/$postId';
      print('Public ID: $publicId');
      
      // Use signed upload
      final signature = _generateSignature(publicId, timestamp);
      
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      // Add signed parameters
      request.fields.addAll({
        'api_key': _apiKey,
        'timestamp': timestamp.toString(),
        'public_id': publicId,
        'signature': signature,
      });
      
      print('Sending request to Cloudinary...');
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      print('Response status: ${response.statusCode}');
      print('Response data: $responseData');
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final imageUrl = jsonResponse['secure_url'] as String;
        print('Upload successful: $imageUrl');
        return imageUrl;
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      userId: userId,
      postId: 'profile',
      folder: 'profiles',
    );
  }

  // Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateDeleteSignature(publicId, timestamp);
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'public_id': publicId,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }
      return false;
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
      return false;
    }
  }

  // Generate transformation URL for different image sizes
  String getTransformedImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
    String crop = 'fill',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl; // Return original if not a Cloudinary URL
    }
    
    // Extract public_id from URL
    final uri = Uri.parse(originalUrl);
    final pathSegments = uri.pathSegments;
    final uploadIndex = pathSegments.indexOf('upload');
    
    if (uploadIndex == -1) return originalUrl;
    
    // Build transformation string
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('c_$crop');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    final transformationString = transformations.join(',');
    
    // Rebuild URL with transformations
    final newPathSegments = List<String>.from(pathSegments);
    newPathSegments.insert(uploadIndex + 1, transformationString);
    
    return uri.replace(pathSegments: newPathSegments).toString();
  }

  // Get thumbnail URL
  String getThumbnailUrl(String originalUrl, {int size = 300}) {
    return getTransformedImageUrl(
      originalUrl,
      width: size,
      height: size,
      crop: 'fill',
    );
  }

  // Get optimized URL for different screen sizes
  String getOptimizedUrl(String originalUrl, {
    required String size, // 'small', 'medium', 'large'
  }) {
    switch (size) {
      case 'small':
        return getTransformedImageUrl(originalUrl, width: 400, height: 400);
      case 'medium':
        return getTransformedImageUrl(originalUrl, width: 800, height: 600);
      case 'large':
        return getTransformedImageUrl(originalUrl, width: 1200, height: 900);
      default:
        return originalUrl;
    }
  }

  // Generate signature for upload
  String _generateSignature(String publicId, int timestamp) {
    final params = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(params);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Generate signature for delete
  String _generateDeleteSignature(String publicId, int timestamp) {
    final params = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(params);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Validate image file
  bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  // Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is acceptable (max 10MB)
  bool isFileSizeAcceptable(File file, {double maxSizeMB = 10.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }
}