/// Educational Content API Models
///
/// Type-safe models for backend API communication
/// Handles JSON serialization/deserialization and data conversion

import 'package:equatable/equatable.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:juan_heart/models/educational_content.dart';

/// Generic API response wrapper
///
/// Wraps all API responses with consistent structure:
/// - success: Boolean indicating if request succeeded
/// - data: The actual response data (type T)
/// - meta: Optional metadata (pagination, counts, etc.)
/// - error: Error message if success is false
class EducationalContentApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final EducationalContentApiMeta? meta;
  final String? error;

  const EducationalContentApiResponse({
    required this.success,
    this.data,
    this.meta,
    this.error,
  });

  /// Create from JSON with custom data parser
  ///
  /// [json] - Raw JSON map from API
  /// [dataParser] - Function to convert data field to type T
  factory EducationalContentApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) dataParser,
  ) {
    return EducationalContentApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? dataParser(json['data']) : null,
      meta: json['meta'] != null
          ? EducationalContentApiMeta.fromJson(json['meta'])
          : null,
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, data, meta, error];

  @override
  String toString() {
    return 'EducationalContentApiResponse(success: $success, '
        'hasData: ${data != null}, error: $error)';
  }
}

/// API response metadata
///
/// Contains pagination info and aggregate statistics
class EducationalContentApiMeta extends Equatable {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int totalViews;

  const EducationalContentApiMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.totalViews,
  });

  /// Create from JSON
  factory EducationalContentApiMeta.fromJson(Map<String, dynamic> json) {
    return EducationalContentApiMeta(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      lastPage: json['last_page'] as int? ?? 1,
      totalViews: json['total_views'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
      'last_page': lastPage,
      'total_views': totalViews,
    };
  }

  @override
  List<Object?> get props => [currentPage, perPage, total, lastPage, totalViews];

  @override
  String toString() {
    return 'EducationalContentApiMeta(page: $currentPage/$lastPage, '
        'total: $total, totalViews: $totalViews)';
  }
}

/// Educational content model from API
///
/// Represents a single educational article/content from backend
/// Can be converted to EducationalContent model for local use
class EducationalContentApiModel extends Equatable {
  final String id;
  final String category;
  final String title;
  final String? titleFil;
  final String? description;
  final String? descriptionFil;
  final String body;
  final String? bodyFil;
  final int readingTimeMinutes;
  final String? imageUrl;
  final String? author;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EducationalContentApiModel({
    required this.id,
    required this.category,
    required this.title,
    this.titleFil,
    this.description,
    this.descriptionFil,
    required this.body,
    this.bodyFil,
    required this.readingTimeMinutes,
    this.imageUrl,
    this.author,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  ///
  /// Supports both single-language and bilingual backend responses:
  /// - Single-language: title, description, body
  /// - Bilingual: title_en/title_fil, description_en/description_fil, body_en/body_fil
  factory EducationalContentApiModel.fromJson(Map<String, dynamic> json) {
    return EducationalContentApiModel(
      id: json['id']?.toString() ?? '',
      category: json['category'] as String? ?? 'cvd_prevention',
      // Support both naming conventions: 'title' and 'title_en'
      title: json['title_en'] as String? ?? json['title'] as String? ?? '',
      titleFil: json['title_fil'] as String?,
      description: json['description_en'] as String? ?? json['description'] as String?,
      descriptionFil: json['description_fil'] as String?,
      body: json['body_en'] as String? ?? json['body'] as String? ?? '',
      bodyFil: json['body_fil'] as String?,
      readingTimeMinutes: json['reading_time_minutes'] as int? ?? 5,
      imageUrl: json['image_url'] as String?,
      author: json['author'] as String?,
      views: json['views'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title_en': title,
      'title_fil': titleFil,
      'description_en': description,
      'description_fil': descriptionFil,
      'body_en': body,
      'body_fil': bodyFil,
      'reading_time_minutes': readingTimeMinutes,
      'image_url': imageUrl,
      'author': author,
      'views': views,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to EducationalContent model for local use
  ///
  /// Maps backend API model to app's domain model
  /// Supports bilingual content with automatic fallback:
  /// - Filipino content uses titleFil/bodyFil if available
  /// - Falls back to English (title/body) if Filipino content is null or empty
  EducationalContent toEducationalContent() {
    // Parse category from string
    ContentCategory parsedCategory;
    try {
      parsedCategory = ContentCategoryExtension.fromString(category);
    } catch (e) {
      parsedCategory = ContentCategory.cvdPrevention;
    }

    // Extract tags from title and description
    final tags = <String>[];
    if (title.isNotEmpty) {
      tags.addAll(title.toLowerCase().split(' ').take(3));
    }

    // Bilingual content with fallback to English
    final filipinoTitle = (titleFil != null && titleFil!.isNotEmpty) ? titleFil! : title;
    final filipinoDescription = (descriptionFil != null && descriptionFil!.isNotEmpty)
        ? descriptionFil!
        : description;
    final filipinoBody = (bodyFil != null && bodyFil!.isNotEmpty) ? bodyFil! : body;

    return EducationalContent(
      id: id,
      titleEn: title,
      titleFil: filipinoTitle,
      category: parsedCategory,
      summaryEn: description ?? _extractSummary(body),
      summaryFil: filipinoDescription ?? _extractSummary(filipinoBody),
      htmlContentEn: body,
      htmlContentFil: filipinoBody,
      imageUrls: imageUrl != null ? [imageUrl!] : [],
      tags: tags,
      version: 1,
      publishedAt: createdAt,
      cachedAt: DateTime.now(),
      readTimeMinutes: readingTimeMinutes,
    );
  }

  /// Extract summary from HTML body (first 200 characters)
  String _extractSummary(String htmlBody) {
    // Remove HTML tags for summary
    final plainText = htmlBody
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (plainText.length <= 200) {
      return plainText;
    }

    return '${plainText.substring(0, 197)}...';
  }

  @override
  List<Object?> get props => [
        id,
        category,
        title,
        titleFil,
        description,
        descriptionFil,
        body,
        bodyFil,
        readingTimeMinutes,
        imageUrl,
        author,
        views,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'EducationalContentApiModel(id: $id, title: $title, '
        'category: $category, views: $views)';
  }
}

/// Content statistics model
///
/// Aggregate statistics for educational content
class ContentStatsModel extends Equatable {
  final int totalContent;
  final int totalViews;
  final Map<String, int> byCategory;

  const ContentStatsModel({
    required this.totalContent,
    required this.totalViews,
    required this.byCategory,
  });

  /// Create from JSON
  factory ContentStatsModel.fromJson(Map<String, dynamic> json) {
    final byCategory = <String, int>{};

    final byCategoryRaw = json['by_category'];
    if (byCategoryRaw != null && byCategoryRaw is Map) {
      byCategoryRaw.forEach((key, value) {
        byCategory[key.toString()] = (value is int) ? value : 0;
      });
    }

    return ContentStatsModel(
      totalContent: json['total_content'] as int? ?? 0,
      totalViews: json['total_views'] as int? ?? 0,
      byCategory: byCategory,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_content': totalContent,
      'total_views': totalViews,
      'by_category': byCategory,
    };
  }

  @override
  List<Object?> get props => [totalContent, totalViews, byCategory];

  @override
  String toString() {
    return 'ContentStatsModel(totalContent: $totalContent, '
        'totalViews: $totalViews, categories: ${byCategory.length})';
  }
}

/// Custom exception for Educational Content API errors
class EducationalContentApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  const EducationalContentApiException({
    required this.message,
    this.statusCode,
    this.error,
  });

  /// Check if error is network-related (no connection or timeout)
  bool get isNetworkError =>
      statusCode == null || statusCode == 408 || statusCode! >= 500;

  /// Check if error is client-side (4xx)
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Check if error is server-side (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    final buffer = StringBuffer('EducationalContentApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    return buffer.toString();
  }
}
