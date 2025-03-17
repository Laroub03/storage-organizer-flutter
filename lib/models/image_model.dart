import 'dart:typed_data';

class ImageMetadata {
  final int id;
  final String filename;
  final String contentType;
  final int size;
  final DateTime uploadedAt;
  final String? uploadedBy;
  
  // Additional fields that might be returned by your API
  final int? productId;
  final int? userId;

  ImageMetadata({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.size,
    required this.uploadedAt,
    this.uploadedBy,
    this.productId,
    this.userId,
  });

  // Factory constructor to create ImageMetadata from JSON
  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      filename: json['filename'] ?? '',
      contentType: json['contentType'] ?? 'image/jpeg',
      size: json['size'] is String ? int.parse(json['size']) : json['size'],
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.parse(json['uploadedAt']) 
          : DateTime.now(),
      uploadedBy: json['uploadedBy'],
      productId: json['productId'] != null 
          ? (json['productId'] is String ? int.parse(json['productId']) : json['productId']) 
          : null,
      userId: json['userId'] != null 
          ? (json['userId'] is String ? int.parse(json['userId']) : json['userId']) 
          : null,
    );
  }

  // Convert ImageMetadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'contentType': contentType,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
      'uploadedBy': uploadedBy,
      'productId': productId,
      'userId': userId,
    };
  }
  
  // Helper to get file extension
  String get fileExtension {
    return filename.contains('.') ? filename.split('.').last : '';
  }
  
  // Helper to check if this is an image
  bool get isImage {
    return contentType.startsWith('image/');
  }
  
  // Get a readable file size
  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Complete image with metadata and binary data
class ImageData {
  final ImageMetadata metadata;
  final Uint8List bytes;

  ImageData({
    required this.metadata,
    required this.bytes,
  });
}