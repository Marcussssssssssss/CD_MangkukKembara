import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Reusable star rating bar widget.
class RatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final bool showLabel;
  final Color? filledColor;
  final Color? labelColor;

  const RatingBar({
    super.key,
    required this.rating,
    this.size = 16,
    this.showLabel = true,
    this.filledColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);
    final filled = filledColor ?? AppColors.starFilled;
    final label = labelColor ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          full,
          (_) =>
              Icon(Icons.star_rounded, size: size, color: filled),
        ),
        if (half)
          Icon(
            Icons.star_half_rounded,
            size: size,
            color: filled,
          ),
        ...List.generate(
          empty,
          (_) => Icon(
            Icons.star_outline_rounded,
            size: size,
            color: AppColors.starEmpty,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w700,
              color: label,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tappable star rating selector (for forms).
class RatingSelector extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  const RatingSelector({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1.0;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: rating >= star
                  ? AppColors.starFilled
                  : AppColors.starEmpty,
            ),
          ),
        );
      }),
    );
  }
}
