import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/app_colors.dart';

/// Shimmer loading skeleton for list/grid items.
class LoadingWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool useGrid;

  const LoadingWidget({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 120,
    this.useGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.background,
      child: useGrid ? _buildGrid() : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: _ShimmerCard(height: itemHeight),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const _ShimmerCard(height: 0),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height > 0 ? height : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 12, width: 200, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 12, width: 140, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Simple centered spinner.
class LoadingSpinner extends StatelessWidget {
  final String? message;
  const LoadingSpinner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
