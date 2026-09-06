import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import 'app_network_image.dart';
import 'rating_bar.dart';

/// Vendor card used in list views and search results.
class VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onTap;

  const VendorCard({super.key, required this.vendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const coverColor = AppColors.primary;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: coverColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        vendor.coverImageUrl != null &&
                            vendor.coverImageUrl!.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl: vendor.coverImageUrl,
                            fit: BoxFit.cover,
                            targetOptimizationWidth: 720,
                            errorWidget: const _VendorCoverFallback(),
                          )
                        : const _VendorCoverFallback(),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: vendor.isOpen
                            ? AppColors.success
                            : AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vendor.isOpen ? 'Open' : 'Closed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          vendor.state,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vendor.distanceKm != null) ...[
                        Text(
                          '${vendor.distanceKm!.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingBar(rating: vendor.averageRating, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '(${vendor.reviewCount})',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: vendor.heritageFoods
                        .take(3)
                        .map(
                          (food) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tagBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              food,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.tagText),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorCoverFallback extends StatelessWidget {
  const _VendorCoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 48,
          color: Colors.white.withAlpha(100),
        ),
      ),
    );
  }
}
