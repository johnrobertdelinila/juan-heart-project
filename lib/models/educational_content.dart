import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:juan_heart/models/content_category.dart';

part 'educational_content.g.dart';

/// Model representing educational content for CVD prevention.
/// Supports offline-first architecture with bilingual content.
@HiveType(typeId: 10)
class EducationalContent extends Equatable {
  /// Unique identifier for the content
  @HiveField(0)
  final String id;

  /// English title
  @HiveField(1)
  final String titleEn;

  /// Filipino (Tagalog) title
  @HiveField(2)
  final String titleFil;

  /// Content category for filtering
  @HiveField(3)
  final ContentCategory category;

  /// English summary/excerpt
  @HiveField(4)
  final String summaryEn;

  /// Filipino summary/excerpt
  @HiveField(5)
  final String summaryFil;

  /// Full HTML content in English
  @HiveField(6)
  final String htmlContentEn;

  /// Full HTML content in Filipino
  @HiveField(7)
  final String htmlContentFil;

  /// List of image URLs used in content
  @HiveField(8)
  final List<String> imageUrls;

  /// Search tags for content discovery
  @HiveField(9)
  final List<String> tags;

  /// Version number for update management
  @HiveField(10)
  final int version;

  /// When the content was published
  @HiveField(11)
  final DateTime publishedAt;

  /// When the content was cached locally (null if not cached)
  @HiveField(12)
  final DateTime? cachedAt;

  /// Estimated reading time in minutes
  @HiveField(13)
  final int readTimeMinutes;

  const EducationalContent({
    required this.id,
    required this.titleEn,
    required this.titleFil,
    required this.category,
    required this.summaryEn,
    required this.summaryFil,
    required this.htmlContentEn,
    required this.htmlContentFil,
    required this.imageUrls,
    required this.tags,
    required this.version,
    required this.publishedAt,
    this.cachedAt,
    required this.readTimeMinutes,
  });

  /// Check if content is available offline
  bool get isOfflineAvailable => cachedAt != null;

  /// Check if content was published recently (within 30 days)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inDays <= 30;
  }

  /// Get title in specified language
  String getTitle(String languageCode) {
    return languageCode == 'fil' ? titleFil : titleEn;
  }

  /// Get summary in specified language
  String getSummary(String languageCode) {
    return languageCode == 'fil' ? summaryFil : summaryEn;
  }

  /// Get HTML content in specified language
  String getHtmlContent(String languageCode) {
    return languageCode == 'fil' ? htmlContentFil : htmlContentEn;
  }

  /// Create a copy with modified fields
  EducationalContent copyWith({
    String? id,
    String? titleEn,
    String? titleFil,
    ContentCategory? category,
    String? summaryEn,
    String? summaryFil,
    String? htmlContentEn,
    String? htmlContentFil,
    List<String>? imageUrls,
    List<String>? tags,
    int? version,
    DateTime? publishedAt,
    DateTime? cachedAt,
    int? readTimeMinutes,
  }) {
    return EducationalContent(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleFil: titleFil ?? this.titleFil,
      category: category ?? this.category,
      summaryEn: summaryEn ?? this.summaryEn,
      summaryFil: summaryFil ?? this.summaryFil,
      htmlContentEn: htmlContentEn ?? this.htmlContentEn,
      htmlContentFil: htmlContentFil ?? this.htmlContentFil,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      publishedAt: publishedAt ?? this.publishedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
    );
  }

  /// Convert to JSON for API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleFil': titleFil,
      'category': category.value,
      'summaryEn': summaryEn,
      'summaryFil': summaryFil,
      'htmlContentEn': htmlContentEn,
      'htmlContentFil': htmlContentFil,
      'imageUrls': imageUrls,
      'tags': tags,
      'version': version,
      'publishedAt': publishedAt.toIso8601String(),
      'cachedAt': cachedAt?.toIso8601String(),
      'readTimeMinutes': readTimeMinutes,
    };
  }

  /// Create from JSON
  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      id: json['id'] as String,
      titleEn: json['titleEn'] as String,
      titleFil: json['titleFil'] as String,
      category: ContentCategoryExtension.fromString(
        json['category'] as String? ?? 'cvdPrevention',
      ),
      summaryEn: json['summaryEn'] as String,
      summaryFil: json['summaryFil'] as String,
      htmlContentEn: json['htmlContentEn'] as String,
      htmlContentFil: json['htmlContentFil'] as String,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      tags: List<String>.from(json['tags'] as List? ?? []),
      version: json['version'] as int? ?? 1,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      cachedAt: json['cachedAt'] != null
          ? DateTime.parse(json['cachedAt'] as String)
          : null,
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 5,
    );
  }

  /// Validate content data
  bool isValid() {
    return id.isNotEmpty &&
        titleEn.isNotEmpty &&
        titleFil.isNotEmpty &&
        htmlContentEn.isNotEmpty &&
        htmlContentFil.isNotEmpty &&
        readTimeMinutes > 0;
  }

  /// Estimate content size in bytes (for cache management)
  int estimateSizeInBytes() {
    final titleSize = titleEn.length + titleFil.length;
    final summarySize = summaryEn.length + summaryFil.length;
    final contentSize = htmlContentEn.length + htmlContentFil.length;
    final tagsSize = tags.join('').length;
    final imagesSize = imageUrls.join('').length;

    return (titleSize + summarySize + contentSize + tagsSize + imagesSize) * 2;
  }

  @override
  List<Object?> get props => [
        id,
        titleEn,
        titleFil,
        category,
        summaryEn,
        summaryFil,
        htmlContentEn,
        htmlContentFil,
        imageUrls,
        tags,
        version,
        publishedAt,
        cachedAt,
        readTimeMinutes,
      ];

  @override
  String toString() {
    return 'EducationalContent(id: $id, titleEn: $titleEn, '
        'category: ${category.labelEn}, version: $version, '
        'isOfflineAvailable: $isOfflineAvailable)';
  }
}
