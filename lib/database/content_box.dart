import 'package:hive/hive.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/models/content_category.dart';

/// Hive box manager for educational content storage.
/// Provides offline-first access to CVD prevention articles.
class ContentBox {
  static const String _boxName = 'educational_content';
  static const int _maxArticles = 50;
  static const int _maxArticleSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int _maxTotalCacheSizeBytes = 100 * 1024 * 1024; // 100MB

  Box<EducationalContent>? _box;

  /// Singleton pattern
  static final ContentBox _instance = ContentBox._internal();
  factory ContentBox() => _instance;
  ContentBox._internal();

  /// Get singleton instance
  static ContentBox get instance => _instance;

  /// Initialize the Hive box
  Future<void> initialize() async {
    try {
      if (_box == null || !_box!.isOpen) {
        _box = await Hive.openBox<EducationalContent>(_boxName);
        print('Educational content box initialized with ${_box!.length} items');
      }
    } catch (e) {
      print('Error initializing educational content box: $e');
      rethrow;
    }
  }

  /// Ensure box is initialized
  Future<Box<EducationalContent>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
    return _box!;
  }

  /// Save content to cache
  Future<void> saveContent(EducationalContent content) async {
    try {
      final box = await _getBox();

      // Check article size limit
      final sizeInBytes = content.estimateSizeInBytes();
      if (sizeInBytes > _maxArticleSizeBytes) {
        throw Exception(
          'Article size ($sizeInBytes bytes) exceeds limit ($_maxArticleSizeBytes bytes)',
        );
      }

      // Mark as cached
      final cachedContent = content.copyWith(cachedAt: DateTime.now());

      // Check if we need to enforce cache limits before saving
      if (!box.containsKey(content.id)) {
        await _enforceCacheLimitsBeforeSave();
      }

      await box.put(content.id, cachedContent);
      print('Saved content: ${content.id} (${content.titleEn})');
    } catch (e) {
      print('Error saving content ${content.id}: $e');
      rethrow;
    }
  }

  /// Save multiple content items
  Future<void> saveMultipleContent(List<EducationalContent> contents) async {
    try {
      final box = await _getBox();

      // Convert to map with cached timestamps
      final Map<String, EducationalContent> contentMap = {};
      for (final content in contents) {
        final cachedContent = content.copyWith(cachedAt: DateTime.now());
        contentMap[content.id] = cachedContent;
      }

      await box.putAll(contentMap);
      print('Saved ${contents.length} content items');
    } catch (e) {
      print('Error saving multiple content: $e');
      rethrow;
    }
  }

  /// Get content by ID
  Future<EducationalContent?> getContent(String id) async {
    try {
      final box = await _getBox();
      return box.get(id);
    } catch (e) {
      print('Error getting content $id: $e');
      return null;
    }
  }

  /// Get all cached content
  Future<List<EducationalContent>> getAllContent() async {
    try {
      final box = await _getBox();
      return box.values.toList();
    } catch (e) {
      print('Error getting all content: $e');
      return [];
    }
  }

  /// Get content by category
  Future<List<EducationalContent>> getByCategory(String category) async {
    try {
      final box = await _getBox();
      return box.values
          .where((content) => content.category.value == category)
          .toList();
    } catch (e) {
      print('Error getting content by category: $e');
      return [];
    }
  }

  /// Check if content exists in cache
  Future<bool> hasContent(String id) async {
    try {
      final box = await _getBox();
      return box.containsKey(id);
    } catch (e) {
      print('Error checking content existence: $e');
      return false;
    }
  }

  /// Delete content by ID
  Future<void> deleteContent(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
      print('Deleted content: $id');
    } catch (e) {
      print('Error deleting content $id: $e');
      rethrow;
    }
  }

  /// Clear all cached content
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      print('Cleared all educational content cache');
    } catch (e) {
      print('Error clearing content cache: $e');
      rethrow;
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSizeBytes() async {
    try {
      final box = await _getBox();
      int totalSize = 0;

      for (final content in box.values) {
        totalSize += content.estimateSizeInBytes();
      }

      return totalSize;
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Get number of cached articles
  Future<int> getCachedCount() async {
    try {
      final box = await _getBox();
      return box.length;
    } catch (e) {
      print('Error getting cached count: $e');
      return 0;
    }
  }

  /// Enforce cache limits (remove oldest if needed)
  Future<bool> enforceCacheLimits() async {
    try {
      final box = await _getBox();

      // Check article count limit
      if (box.length > _maxArticles) {
        await _removeOldestArticles(box.length - _maxArticles);
      }

      // Check total size limit
      final totalSize = await getCacheSizeBytes();
      if (totalSize > _maxTotalCacheSizeBytes) {
        // Remove articles until under limit
        await _removeOldestUntilUnderSizeLimit();
      }

      return true;
    } catch (e) {
      print('Error enforcing cache limits: $e');
      return false;
    }
  }

  /// Enforce cache limits before saving new content
  Future<void> _enforceCacheLimitsBeforeSave() async {
    final box = await _getBox();

    // If at max capacity, remove one oldest article
    if (box.length >= _maxArticles) {
      await _removeOldestArticles(1);
    }
  }

  /// Remove oldest articles by cached date
  Future<void> _removeOldestArticles(int count) async {
    try {
      final box = await _getBox();
      final allContent = box.values.toList();

      // Sort by cached date (oldest first)
      allContent.sort((a, b) {
        final aDate = a.cachedAt ?? DateTime.now();
        final bDate = b.cachedAt ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      // Remove oldest
      for (int i = 0; i < count && i < allContent.length; i++) {
        await box.delete(allContent[i].id);
      }

      print('Removed $count oldest articles from cache');
    } catch (e) {
      print('Error removing oldest articles: $e');
      rethrow;
    }
  }

  /// Remove oldest articles until under size limit
  Future<void> _removeOldestUntilUnderSizeLimit() async {
    try {
      final box = await _getBox();
      int currentSize = await getCacheSizeBytes();

      while (currentSize > _maxTotalCacheSizeBytes && box.isNotEmpty) {
        await _removeOldestArticles(1);
        currentSize = await getCacheSizeBytes();
      }

      print('Cache size reduced to $currentSize bytes');
    } catch (e) {
      print('Error reducing cache size: $e');
      rethrow;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final count = await getCachedCount();
      final sizeBytes = await getCacheSizeBytes();
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);

      return {
        'count': count,
        'maxCount': _maxArticles,
        'sizeBytes': sizeBytes,
        'sizeMB': sizeMB,
        'maxSizeMB': (_maxTotalCacheSizeBytes / (1024 * 1024)).toInt(),
        'utilizationPercent':
            ((sizeBytes / _maxTotalCacheSizeBytes) * 100).toStringAsFixed(1),
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {};
    }
  }

  /// Close the box
  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
        _box = null;
        print('Educational content box closed');
      }
    } catch (e) {
      print('Error closing content box: $e');
    }
  }
}
