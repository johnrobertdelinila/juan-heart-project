import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Memory-efficient cached image widget with placeholders and error handling
/// Supports both asset and network images with optimized caching
class CachedImage extends StatelessWidget {
  /// Asset path for the image
  final String? assetPath;

  /// Network URL for the image
  final String? networkUrl;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Box fit for the image
  final BoxFit fit;

  /// Placeholder widget while loading
  final Widget? placeholder;

  /// Error widget when image fails to load
  final Widget? errorWidget;

  /// Whether to show shimmer effect while loading
  final bool showShimmer;

  /// Border radius for the image
  final BorderRadius? borderRadius;

  /// Color filter to apply to the image
  final ColorFilter? colorFilter;

  /// Alignment of the image within its bounds
  final Alignment alignment;

  /// Whether to use memory-efficient caching
  final bool enableCache;

  /// Cache width for optimization (null = use actual width)
  final int? cacheWidth;

  /// Cache height for optimization (null = use actual height)
  final int? cacheHeight;

  const CachedImage.asset(
    this.assetPath, {
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = false,
    this.borderRadius,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.enableCache = true,
    this.cacheWidth,
    this.cacheHeight,
  })  : networkUrl = null,
        super(key: key);

  const CachedImage.network(
    this.networkUrl, {
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = true,
    this.borderRadius,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.enableCache = true,
    this.cacheWidth,
    this.cacheHeight,
  })  : assetPath = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (assetPath != null) {
      imageWidget = _buildAssetImage();
    } else if (networkUrl != null) {
      imageWidget = _buildNetworkImage();
    } else {
      imageWidget = _buildErrorWidget();
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // Wrap in sized box if dimensions specified
    if (width != null || height != null) {
      imageWidget = SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build asset image with caching
  Widget _buildAssetImage() {
    try {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorBlendMode: colorFilter != null ? BlendMode.srcIn : null,
        color: colorFilter != null ? Colors.transparent : null,
        cacheWidth: enableCache ? cacheWidth : null,
        cacheHeight: enableCache ? cacheHeight : null,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset image $assetPath: $error');
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      debugPrint('Exception loading asset image $assetPath: $e');
      return _buildErrorWidget();
    }
  }

  /// Build network image with caching and loading states
  Widget _buildNetworkImage() {
    return Image.network(
      networkUrl!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: enableCache ? cacheWidth : null,
      cacheHeight: enableCache ? cacheHeight : null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading network image $networkUrl: $error');
        return _buildErrorWidget();
      },
    );
  }

  /// Build placeholder widget
  Widget _buildPlaceholder() {
    if (placeholder != null) {
      return placeholder!;
    }

    if (showShimmer) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: JHTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized icon image widget for navigation and small icons
class CachedIconImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final BoxFit fit;

  const CachedIconImage({
    Key? key,
    required this.assetPath,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedImage.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      // Use cache dimensions for memory optimization
      cacheWidth: (size * 2).toInt(), // 2x for retina displays
      cacheHeight: (size * 2).toInt(),
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      errorWidget: Icon(
        Icons.image,
        size: size,
        color: color ?? Colors.grey,
      ),
    );
  }
}

/// Optimized avatar image widget with circular clipping
class CachedAvatarImage extends StatelessWidget {
  final String? assetPath;
  final String? networkUrl;
  final double size;
  final Widget? placeholder;
  final IconData? fallbackIcon;

  const CachedAvatarImage.asset(
    this.assetPath, {
    Key? key,
    this.size = 48,
    this.placeholder,
    this.fallbackIcon,
  })  : networkUrl = null,
        super(key: key);

  const CachedAvatarImage.network(
    this.networkUrl, {
    Key? key,
    this.size = 48,
    this.placeholder,
    this.fallbackIcon,
  })  : assetPath = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (assetPath != null) {
      imageWidget = CachedImage.asset(
        assetPath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt(),
        cacheHeight: (size * 2).toInt(),
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: placeholder,
        errorWidget: _buildFallback(),
      );
    } else if (networkUrl != null) {
      imageWidget = CachedImage.network(
        networkUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt(),
        cacheHeight: (size * 2).toInt(),
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: placeholder,
        errorWidget: _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
    }

    return ClipOval(
      child: imageWidget,
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        fallbackIcon ?? Icons.person,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}
