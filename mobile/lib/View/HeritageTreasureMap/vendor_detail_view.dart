import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageTreasureMap/vendor_detail_view_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/operating_hour_model.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/rating_bar.dart';

/// A3. Vendor Details View.
class VendorDetailView extends StatefulWidget {
  final String vendorId;
  const VendorDetailView({super.key, required this.vendorId});

  @override
  State<VendorDetailView> createState() => _VendorDetailViewState();
}

class _VendorDetailViewState extends State<VendorDetailView> {
  late final VendorDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = VendorDetailViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadVendor(widget.vendorId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<VendorDetailViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: vm.isLoading
              ? const LoadingSpinner(message: 'Loading vendor details...')
              : vm.hasError || vm.vendor == null
              ? ErrorStateWidget(onRetry: () => _vm.retry(widget.vendorId))
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadVendor(widget.vendorId, showLoading: false),
                  child: _buildContent(ctx, vm),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, VendorDetailViewModel vm) {
    final v = vm.vendor!;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: v.coverImageUrl != null && v.coverImageUrl!.isNotEmpty
                ? GestureDetector(
                    onTap: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _FullscreenVendorImageView(
                          imageUrl: v.coverImageUrl!,
                          vendorName: v.name,
                        ),
                      ),
                    ),
                    child: AppNetworkImage(
                      imageUrl: v.coverImageUrl,
                      fit: BoxFit.cover,
                      targetOptimizationWidth: 1200,
                      errorWidget: const _VendorCoverPlaceholder(),
                    ),
                  )
                : const _VendorCoverPlaceholder(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.directions_rounded),
              tooltip: 'Navigate to vendor',
              onPressed: () => Navigator.pushNamed(
                ctx,
                AppRoutes.routeNavigation,
                arguments: v.id,
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic info
              _InfoCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          v.name,
                          style: Theme.of(ctx).textTheme.headlineSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: v.isOpen
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          v.isOpen ? 'Open Now' : 'Closed',
                          style: TextStyle(
                            color: v.isOpen
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RatingBar(rating: v.averageRating, size: 18),
                  Text(
                    '${v.reviewCount} reviews',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    v.description,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Contact info
              _InfoCard(
                title: 'Contact & Location',
                children: [
                  _InfoRow(
                    Icons.person_outline_rounded,
                    'Contact Person',
                    v.contactPerson,
                  ),
                  if (v.contactNumber != null)
                    _InfoRow(Icons.phone_outlined, 'Phone', v.contactNumber!),
                  if (v.email != null)
                    _InfoRow(Icons.email_outlined, 'Email', v.email!),
                  _InfoRow(
                    Icons.business_rounded,
                    'Business Type',
                    v.businessType,
                  ),
                  _InfoRow(Icons.location_on_outlined, 'Address', v.address),
                  _InfoRow(Icons.map_outlined, 'State', v.state),
                ],
              ),

              // Heritage foods
              _InfoCard(
                title: 'Heritage Foods',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: v.heritageFoods
                        .map(
                          (food) => Chip(
                            label: Text(food),
                            avatar: const Icon(
                              Icons.rice_bowl_rounded,
                              size: 16,
                            ),
                            backgroundColor: AppColors.tagBg,
                            labelStyle: const TextStyle(
                              color: AppColors.tagText,
                              fontSize: 13,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),

              // Operating hours
              if (vm.operatingHours.isNotEmpty)
                _InfoCard(
                  title: 'Operating Hours',
                  children: [...vm.operatingHours.map((h) => _HoursRow(h))],
                ),

              // Tiffin designs carried by this vendor
              if (vm.tiffins.isNotEmpty)
                _InfoCard(
                  title: 'Heritage Tiffin Designs',
                  children: [
                    ...vm.tiffins.map(
                      (t) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: t.coverImageUrl != null
                                ? AppNetworkImage(
                                    imageUrl: t.coverImageUrl,
                                    fit: BoxFit.cover,
                                    targetOptimizationWidth: 200,
                                    errorWidget:
                                        const _TiffinImagePlaceholder(),
                                  )
                                : const _TiffinImagePlaceholder(),
                          ),
                        ),
                        title: Text(
                          t.tiffinEditionName,
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(
                          ctx,
                          AppRoutes.tiffinExperience,
                          arguments: t.tiffinId,
                        ),
                      ),
                    ),
                  ],
                ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review_rounded),
                      label: const Text('View Reviews'),
                      onPressed: () => Navigator.pushNamed(
                        ctx,
                        AppRoutes.community,
                        arguments: {'vendorId': v.id, 'vendorName': v.name},
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Get Directions'),
                      onPressed: () => Navigator.pushNamed(
                        ctx,
                        AppRoutes.routeNavigation,
                        arguments: v.id,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullscreenVendorImageView extends StatelessWidget {
  final String imageUrl;
  final String vendorName;

  const _FullscreenVendorImageView({
    required this.imageUrl,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(vendorName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: AppNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              targetOptimizationWidth: 1800,
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorCoverPlaceholder extends StatelessWidget {
  const _VendorCoverPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary, AppColors.primary.withAlpha(180)],
      ),
    ),
    child: Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 64,
        color: Colors.white.withAlpha(200),
      ),
    ),
  );
}

class _TiffinImagePlaceholder extends StatelessWidget {
  const _TiffinImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.kitchen_rounded, color: AppColors.textHint),
  );
}

class _InfoCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _InfoCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final OperatingHourModel hours;
  const _HoursRow(this.hours);

  @override
  Widget build(BuildContext context) {
    final today = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][DateTime.now().weekday - 1];
    final isToday = hours.dayName == today;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              hours.dayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                color: isToday ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(
            hours.displayHours,
            style: TextStyle(
              fontSize: 13,
              color: hours.isClosed ? AppColors.error : AppColors.textSecondary,
              fontWeight: hours.isClosed ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
