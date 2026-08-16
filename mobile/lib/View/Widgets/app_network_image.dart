import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/app_colors.dart';
import '../../core/utils/cloudinary_utils.dart';

/// Performance-optimized network image widget.
/// Applies Cloudinary URL transformations (f_auto, q_auto, w_width) and
/// caches images locally in memory and disk using CachedNetworkImage.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int targetOptimizationWidth;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.targetOptimizationWidth = 800,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final optimizedUrl = CloudinaryUtils.getOptimizedUrl(
      imageUrl,
      width: targetOptimizationWidth,
    );

    if (optimizedUrl.isEmpty) {
      return errorWidget ?? _buildErrorFallback();
    }

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorFallback(),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: Colors.white.withAlpha(128),
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildErrorFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}
