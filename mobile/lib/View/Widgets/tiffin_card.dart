import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../Model/Repositories/HeritageExperience/heritage_tiffin_model.dart';
import 'app_network_image.dart';

/// Heritage tiffin card for the experience grid.
class TiffinCard extends StatelessWidget {
  final HeritageTiffinModel tiffin;
  final VoidCallback onTap;
  final Color? primaryColor;
  final Color? mutedColor;
  final Color? borderColor;
  final String? backgroundAsset;

  const TiffinCard({
    super.key,
    required this.tiffin,
    required this.onTap,
    this.primaryColor,
    this.mutedColor,
    this.borderColor,
    this.backgroundAsset,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = primaryColor ?? AppColors.primary;
    final muted = mutedColor ?? AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor ?? Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / Banner
            SizedBox(
              height: 164,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: backgroundAsset == null
                        ? Container(
                            color: cardColor.withAlpha(25),
                          )
                        : Image.asset(
                            backgroundAsset!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                  if (tiffin.coverImageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: AppNetworkImage(
                        imageUrl: tiffin.coverImageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: _fallback(tiffin),
                      ),
                    )
                  else
                    _fallback(tiffin),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tiffin.editionName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cardColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: muted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          tiffin.state,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to explore',
                    style: TextStyle(
                      fontSize: 11,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(HeritageTiffinModel tiffin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen_rounded,
            size: 44,
            color: Colors.white.withAlpha(220),
          ),
          const SizedBox(height: 4),
          Text(
            tiffin.stateCode,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
