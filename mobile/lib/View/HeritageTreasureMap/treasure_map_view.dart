import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/HeritageTreasureMap/treasure_map_view_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/pasar_malam_model.dart';
import '../Widgets/app_bottom_nav.dart';
import '../Widgets/vendor_card.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';

/// A1. Heritage Treasure Map View — the application home screen.
class TreasureMapView extends StatefulWidget {
  const TreasureMapView({super.key});

  @override
  State<TreasureMapView> createState() => _TreasureMapViewState();
}

class _TreasureMapViewState extends State<TreasureMapView> {
  late final TreasureMapViewModel _vm;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = TreasureMapViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.loadVendors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TreasureMapViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(ctx, vm),
                  _buildFilters(ctx, vm),
                  Expanded(child: _buildBody(ctx, vm)),
                ],
              ),
              // Vendor Preview Bottom Sheet
              if (vm.previewVendor != null)
                _VendorPreviewSheet(
                  vendor: vm.previewVendor!,
                  onDismiss: vm.clearVendorPreview,
                ),
              if (vm.previewPasarMalam != null)
                _PasarMalamPreviewSheet(
                  market: vm.previewPasarMalam!,
                  vendors: vm.pasarMalamVendors,
                  isLoading: vm.isLoadingPasarMalamVendors,
                  errorMessage: vm.pasarMalamVendorError,
                  onRetry: vm.retryPasarMalamVendors,
                  onRefresh: vm.refreshPasarMalamVendors,
                  onDismiss: vm.clearPasarMalamPreview,
                ),
            ],
          ),
          bottomNavigationBar: const AppBottomNav(selectedIndex: -1),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, TreasureMapViewModel vm) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              // Logo row
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      image: true,
                      label:
                          '${AppConstants.appName}, ${AppConstants.appTagline}',
                      child: SizedBox(
                        height: 58,
                        child: Image.asset(
                          'asset/image/logo_light.png',
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, _, _) => const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppConstants.appName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Map/List toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _ToggleButton(
                          icon: Icons.map_rounded,
                          selected: vm.viewMode == MapViewMode.map,
                          onTap: () => vm.setViewMode(MapViewMode.map),
                        ),
                        _ToggleButton(
                          icon: Icons.list_rounded,
                          selected: vm.viewMode == MapViewMode.list,
                          onTap: () => vm.setViewMode(MapViewMode.list),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search vendors, foods, states...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(160)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white70,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withAlpha(25),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: vm.setSearchQuery,
                onSubmitted: (q) => Navigator.pushNamed(
                  ctx,
                  AppRoutes.vendorSearch,
                  arguments: q,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext ctx, TreasureMapViewModel vm) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 18, right: 10),
            child: Icon(
              Icons.filter_alt_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          Expanded(
            child: _LabeledFilterDropdown(
              label: 'State',
              value: vm.selectedState,
              values: AppConstants.malaysianStates,
              onChanged: vm.setStateFilter,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _LabeledFilterDropdown(
              label: 'Food category',
              value: vm.selectedFoodCategory,
              values: AppConstants.foodCategories,
              onChanged: vm.setFoodCategoryFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, TreasureMapViewModel vm) {
    if (vm.isLoading) return const LoadingWidget(itemCount: 3);
    if (vm.hasError) {
      return ErrorStateWidget(message: vm.errorMessage, onRetry: vm.retry);
    }
    if (vm.isEmpty) {
      return RefreshableStateView(
        onRefresh: () => vm.loadVendors(showLoading: false),
        child: const EmptyStateWidget(
          icon: Icons.storefront_outlined,
          title: 'No vendors found',
          subtitle: 'Try adjusting your search or filters.',
        ),
      );
    }

    if (vm.viewMode == MapViewMode.list) {
      return RefreshIndicator(
        onRefresh: () => vm.loadVendors(showLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Sort vendors',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Nearby', label: Text('Nearby')),
                      ButtonSegment(
                        value: 'Most Rated',
                        label: Text('Most Rated'),
                      ),
                    ],
                    selected: {vm.vendorSort},
                    onSelectionChanged: (selection) =>
                        vm.setVendorSort(selection.first),
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            if (vm.locationMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        vm.locationMessage!,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (vm.pasarMalam.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Pasar Malam',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ...vm.pasarMalam.map(
              (market) => _PasarMalamListCard(
                market: market,
                onTap: () => vm.showPasarMalamPreview(market),
              ),
            ),
            if (vm.vendors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Restaurants, cafés & food stalls',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ...vm.vendors.map(
              (vendor) => VendorCard(
                vendor: vendor,
                onTap: () => Navigator.pushNamed(
                  ctx,
                  AppRoutes.vendorDetail,
                  arguments: vendor.id,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Coordinate overview derived from the vendors returned by Supabase.
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: () => vm.loadVendors(showLoading: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: _VendorCoordinateView(
              vendors: vm.vendors,
              pasarMalam: vm.pasarMalam,
              onVendorTap: vm.showVendorPreview,
              onPasarMalamTap: vm.showPasarMalamPreview,
            ),
          ),
        ),
      ),
    );
  }
}

/// A lightweight coordinate plot; directions open in the real maps app.
class _VendorCoordinateView extends StatelessWidget {
  final List<VendorModel> vendors;
  final List<PasarMalamModel> pasarMalam;
  final void Function(VendorModel) onVendorTap;
  final void Function(PasarMalamModel) onPasarMalamTap;

  const _VendorCoordinateView({
    required this.vendors,
    required this.pasarMalam,
    required this.onVendorTap,
    required this.onPasarMalamTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Neutral coordinate-grid background.
        CustomPaint(
          painter: _MapGridPainter(),
          child: Container(color: AppColors.mapBg),
        ),

        // Legend / info overlay
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vendors.length} places · ${pasarMalam.length} markets',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Tap a pin',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Vendor pins positioned from their stored latitude and longitude.
        ...vendors.asMap().entries.map((entry) {
          final v = entry.value;
          final minLatitude = vendors
              .map((vendor) => vendor.latitude)
              .reduce((a, b) => a < b ? a : b);
          final maxLatitude = vendors
              .map((vendor) => vendor.latitude)
              .reduce((a, b) => a > b ? a : b);
          final minLongitude = vendors
              .map((vendor) => vendor.longitude)
              .reduce((a, b) => a < b ? a : b);
          final maxLongitude = vendors
              .map((vendor) => vendor.longitude)
              .reduce((a, b) => a > b ? a : b);
          final latitudeRange = maxLatitude - minLatitude;
          final longitudeRange = maxLongitude - minLongitude;
          final frac = Offset(
            longitudeRange == 0
                ? 0.5
                : 0.15 + ((v.longitude - minLongitude) / longitudeRange) * 0.7,
            latitudeRange == 0
                ? 0.5
                : 0.15 + (1 - (v.latitude - minLatitude) / latitudeRange) * 0.7,
          );
          return Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Builder(
              builder: (ctx) {
                return LayoutBuilder(
                  builder: (_, constraints) {
                    final x = constraints.maxWidth * frac.dx - 18;
                    final y = constraints.maxHeight * frac.dy - 40;
                    const pinColor = AppColors.primary;
                    return Stack(
                      children: [
                        Positioned(
                          left: x,
                          top: y,
                          child: GestureDetector(
                            onTap: () => onVendorTap(v),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pinColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: pinColor.withAlpha(120),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    v.name.split(' ').first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(width: 2, height: 8, color: pinColor),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: pinColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        }),
        ...pasarMalam.map(
          (market) => _PasarMalamMapPin(
            market: market,
            markets: pasarMalam,
            onTap: () => onPasarMalamTap(market),
          ),
        ),
      ],
    );
  }
}

class _PasarMalamMapPin extends StatelessWidget {
  final PasarMalamModel market;
  final List<PasarMalamModel> markets;
  final VoidCallback onTap;

  const _PasarMalamMapPin({
    required this.market,
    required this.markets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minLat = markets
        .map((m) => m.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = markets
        .map((m) => m.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLng = markets
        .map((m) => m.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = markets
        .map((m) => m.longitude)
        .reduce((a, b) => a > b ? a : b);
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    final dx = lngRange == 0
        ? 0.5
        : 0.15 + ((market.longitude - minLng) / lngRange) * 0.7;
    final dy = latRange == 0
        ? 0.5
        : 0.15 + (1 - (market.latitude - minLat) / latRange) * 0.7;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (_, constraints) => Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * dx - 22,
              top: constraints.maxHeight * dy - 44,
              child: Semantics(
                button: true,
                label: 'Open ${market.name} and its vendors',
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentDark,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentDark.withAlpha(100),
                              blurRadius: 7,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.nightlife_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              market.name.split(' ').take(2).join(' '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 8,
                        color: AppColors.accentDark,
                      ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.accentDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasarMalamListCard extends StatelessWidget {
  final PasarMalamModel market;
  final VoidCallback onTap;

  const _PasarMalamListCard({required this.market, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.accentContainer,
          child: Icon(Icons.nightlife_rounded, color: AppColors.accentDark),
        ),
        title: Text(
          market.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${market.state} · ${market.isOpen ? "Open" : "Closed"}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _PasarMalamPreviewSheet extends StatelessWidget {
  final PasarMalamModel market;
  final List<VendorModel> vendors;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onDismiss;

  const _PasarMalamPreviewSheet({
    required this.market,
    required this.vendors,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 64,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.66,
          ),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.accentContainer,
                  child: Icon(
                    Icons.nightlife_rounded,
                    color: AppColors.accentDark,
                  ),
                ),
                title: Text(
                  market.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${market.address}\n${market.isOpen ? "Open now" : "Closed now"}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onDismiss,
                ),
              ),
              if (market.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      market.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Active vendors',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isLoading
                      ? const Center(
                          key: ValueKey('market-loading'),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : errorMessage != null
                      ? Center(
                          key: const ValueKey('market-error'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Vendors could not be loaded.'),
                                TextButton.icon(
                                  onPressed: onRetry,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : vendors.isEmpty
                      ? RefreshableStateView(
                          key: const ValueKey('market-empty'),
                          onRefresh: onRefresh,
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No active vendors are listed for this Pasar Malam.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          key: const ValueKey('market-vendors'),
                          onRefresh: onRefresh,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: vendors.length,
                            itemBuilder: (_, index) {
                              final vendor = vendors[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.primary,
                                ),
                                title: Text(vendor.name),
                                subtitle: Text(
                                  vendor.heritageFoods.take(2).join(', '),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.vendorDetail,
                                  arguments: vendor.id,
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeWidth = 3;
    final gridPaint = Paint()
      ..color = AppColors.mapGrid
      ..strokeWidth = 1;
    final waterPaint = Paint()..color = AppColors.mapWater;

    // Reference grid lines.
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.45, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );

    // A visual latitude guide.
    final riverPath = Path()
      ..moveTo(size.width * 0.15, 0)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.5,
        size.width * 0.15,
        size.height,
      );
    canvas.drawPath(
      riverPath,
      waterPaint
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke,
    );

    // Draw grid lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Coordinate regions.
    final blockPaint = Paint()
      ..color = const Color(0xFFD4E8B0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.47,
          size.height * 0.37,
          size.width * 0.26,
          size.height * 0.26,
        ),
        const Radius.circular(4),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.0,
          size.height * 0.37,
          size.width * 0.43,
          size.height * 0.26,
        ),
        const Radius.circular(4),
      ),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabeledFilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _LabeledFilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              dropdownColor: Colors.white,
              items: values
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? AppColors.textPrimary : Colors.white70,
        ),
      ),
    );
  }
}

/// Vendor preview bottom sheet overlay.
class _VendorPreviewSheet extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onDismiss;

  const _VendorPreviewSheet({required this.vendor, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    const coverColor = AppColors.primary;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 64, // above bottom nav
      child: GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: coverColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vendor.state} · ${vendor.isOpen ? "Open" : "Closed"}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: vendor.isOpen
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '★ ${vendor.averageRating} · ${vendor.reviewCount} reviews',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: const Text('Navigate'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.routeNavigation,
                          arguments: vendor.id,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text('Details'),
                        onPressed: () {
                          onDismiss();
                          Navigator.pushNamed(
                            context,
                            AppRoutes.vendorDetail,
                            arguments: vendor.id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
