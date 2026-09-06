import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/HeritageTreasureMap/treasure_map_view_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/pasar_malam_model.dart';
import '../Widgets/app_bottom_nav.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/vendor_card.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/rating_bar.dart';

/// Visual tokens used exclusively by the treasure-map home screen.
/// Keeping these local prevents the refreshed map design from altering the
/// existing heritage theme used by the rest of the app.
abstract final class _MapPageColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color softBackground = Color(0xFFF5F7F3);
  static const Color searchField = Color(0xFFEEF3EC);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  static const Color yellow = Color(0xFFF9B10E);
  static const Color selectedTab = Color(0xFFFEF5E4);
  static const Color text = Color(0xFF283427);
  static const Color hint = Color(0xFF929992);
}

/// A1. Heritage Treasure Map View — the application home screen.
class TreasureMapView extends StatefulWidget {
  final bool selectionMode;

  /// Optional heritage-food search supplied by the Food Origin page.
  /// The map's existing search logic uses this to show matching vendors.
  final String initialFoodQuery;

  const TreasureMapView({
    super.key,
    this.selectionMode = false,
    this.initialFoodQuery = '',
  });

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
    final foodQuery = widget.initialFoodQuery.trim();
    if (foodQuery.isNotEmpty) {
      _searchController.text = foodQuery;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (foodQuery.isEmpty) {
        _vm.loadVendors();
      } else {
        _vm.setSearchQuery(foodQuery);
      }
    });
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
          backgroundColor: _MapPageColors.background,
          appBar: widget.selectionMode
              ? AppBar(title: const Text('Choose a Vendor'))
              : null,
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(ctx, vm),
                  if (!widget.selectionMode) _buildFilters(ctx, vm),
                  Expanded(child: _buildBody(ctx, vm)),
                ],
              ),
              // Vendor Preview Bottom Sheet
              if (vm.previewVendor != null)
                _VendorPreviewSheet(
                  vendor: vm.previewVendor!,
                  onDismiss: vm.clearVendorPreview,
                  onSelect: widget.selectionMode
                      ? () => Navigator.pop(ctx, vm.previewVendor)
                      : null,
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
                  onSelectVendor: widget.selectionMode
                      ? (vendor) => Navigator.pop(ctx, vendor)
                      : null,
                ),
            ],
          ),
          bottomNavigationBar: widget.selectionMode
              ? null
              : const AppBottomNav(
                  backgroundColor: _MapPageColors.background,
                  selectedColor: _MapPageColors.yellow,
                  unselectedColor: _MapPageColors.mediumGreen,
                  selectedBackgroundColor: _MapPageColors.selectedTab,
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, TreasureMapViewModel vm) {
    return Container(
      color: _MapPageColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            widget.selectionMode ? 0 : 8,
            16,
            12,
          ),
          child: Column(
            children: [
              if (!widget.selectionMode) ...[
                // Logo row
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        image: true,
                        label:
                            '${AppConstants.appName}, ${AppConstants.appTagline}',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 180,
                            height: 58,
                            child: ClipRect(
                              child: OverflowBox(
                                minWidth: 180,
                                maxWidth: 180,
                                minHeight: 112,
                                maxHeight: 112,
                                child: Image.asset(
                                  'asset/image/mangkuk_kembara_logo_green.png',
                                  width: 180,
                                  height: 112,
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (_, _, _) => const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      AppConstants.appName,
                                      style: TextStyle(
                                        color: _MapPageColors.darkGreen,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
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
                        color: _MapPageColors.softBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _MapPageColors.border),
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
              ],

              // Search bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: _MapPageColors.text),
                decoration: InputDecoration(
                  hintText: 'Search vendors, foods, states...',
                  hintStyle: const TextStyle(color: _MapPageColors.hint),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _MapPageColors.darkGreen,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: _MapPageColors.darkGreen,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _MapPageColors.searchField,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _MapPageColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _MapPageColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _MapPageColors.darkGreen,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: vm.setSearchQuery,
                onSubmitted: vm.setSearchQuery,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext ctx, TreasureMapViewModel vm) {
    return Container(
      color: _MapPageColors.background,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 18, right: 10),
            child: Icon(
              Icons.filter_alt_rounded,
              color: _MapPageColors.yellow,
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
              values: vm.foodCategoryNames,
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
                onTap: () => widget.selectionMode
                    ? Navigator.pop(ctx, vendor)
                    : Navigator.pushNamed(
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

    return Stack(
      children: [
        Positioned.fill(
          child: _VendorGoogleMap(
            // Vendors belonging to a Pasar Malam are shown through the market
            // marker on the default map, then as direct pins during searches.
            vendors: vm.vendors,
            pasarMalam: vm.pasarMalam,
            selectedVendor: vm.previewVendor,
            showCurrentLocation: vm.canShowCurrentLocation,
            onVendorTap: vm.showVendorPreview,
            onPasarMalamTap: vm.showPasarMalamPreview,
          ),
        ),
        if (vm.hasSearchQuery &&
            vm.vendors.isNotEmpty &&
            vm.previewVendor == null &&
            vm.previewPasarMalam == null)
          _SearchResultsPanel(
            query: vm.searchQuery,
            vendors: vm.vendors,
            onVendorTap: (vendor) => widget.selectionMode
                ? Navigator.pop(ctx, vendor)
                : vm.showVendorPreview(vendor),
          ),
      ],
    );
  }
}

/// Interactive map backed by vendor and night-market coordinates in Supabase.
class _VendorGoogleMap extends StatefulWidget {
  final List<VendorModel> vendors;
  final List<PasarMalamModel> pasarMalam;
  final VendorModel? selectedVendor;
  final bool showCurrentLocation;
  final void Function(VendorModel) onVendorTap;
  final void Function(PasarMalamModel) onPasarMalamTap;

  const _VendorGoogleMap({
    required this.vendors,
    required this.pasarMalam,
    this.selectedVendor,
    required this.showCurrentLocation,
    required this.onVendorTap,
    required this.onPasarMalamTap,
  });

  @override
  State<_VendorGoogleMap> createState() => _VendorGoogleMapState();
}

class _VendorGoogleMapState extends State<_VendorGoogleMap> {
  GoogleMapController? _controller;
  BitmapDescriptor? _nightMarketMarkerIcon;
  BitmapDescriptor? _restaurantMarkerIcon;

  static const _malaysia = CameraPosition(
    target: LatLng(4.2105, 101.9758),
    zoom: 5.4,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarkerIcons());
  }

  Future<void> _loadMarkerIcons() async {
    try {
      final configuration = createLocalImageConfiguration(
        context,
        size: const Size(65, 65),
      );
      final icons = await Future.wait([
        BitmapDescriptor.asset(
          configuration,
          'asset/image/nightmarket_tiffin_pin.png',
          width: 65,
          height: 65,
        ),
        BitmapDescriptor.asset(
          configuration,
          'asset/image/restaurant_tiffin_pin.png',
          width: 65,
          height: 65,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _nightMarketMarkerIcon = icons[0];
        _restaurantMarkerIcon = icons[1];
      });
    } catch (_) {
      // The existing default pins remain available as a safe fallback.
    }
  }

  Set<Marker> get _markers => {
    ...widget.vendors.map(
      (vendor) => Marker(
        markerId: MarkerId('vendor_${vendor.id}'),
        position: LatLng(vendor.latitude, vendor.longitude),
        // Custom assets are shared across platforms. The plain default marker
        // is the loading/error fallback because defaultMarkerWithHue is not
        // implemented by google_maps_flutter_web.
        icon: _restaurantMarkerIcon ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(.5, .85),
        zIndexInt: 2,
        infoWindow: InfoWindow(title: vendor.name, snippet: vendor.address),
        onTap: () => widget.onVendorTap(vendor),
      ),
    ),
    ...widget.pasarMalam.map(
      (market) => Marker(
        markerId: MarkerId('market_${market.id}'),
        position: LatLng(market.latitude, market.longitude),
        icon: _nightMarketMarkerIcon ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(.5, .85),
        zIndexInt: 1,
        infoWindow: InfoWindow(title: market.name, snippet: market.address),
        onTap: () => widget.onPasarMalamTap(market),
      ),
    ),
  };

  List<LatLng> get _positions => [
    ...widget.vendors.map((v) => LatLng(v.latitude, v.longitude)),
    ...widget.pasarMalam.map((m) => LatLng(m.latitude, m.longitude)),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          // Calibrated from the reference's ocean tones: raise the imagery's
          // brightness without adding a grey-white veil over the land.
          colorFilter: const ColorFilter.matrix(<double>[
            1.42,
            0,
            0,
            0,
            0,
            0,
            1.47,
            0,
            0,
            0,
            0,
            0,
            1.36,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: GoogleMap(
            initialCameraPosition: _malaysia,
            mapType: MapType.hybrid,
            markers: _markers,
            myLocationButtonEnabled: widget.showCurrentLocation,
            myLocationEnabled: widget.showCurrentLocation,
            compassEnabled: true,
            buildingsEnabled: true,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            // The Maps JavaScript API exposes a separate camera control on
            // web; zoomControlsEnabled only covers the legacy +/- controls.
            webCameraControlEnabled: false,
            onMapCreated: (controller) {
              _controller = controller;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _fitVisiblePlaces(),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _fitVisiblePlaces() async {
    final controller = _controller;
    final positions = _positions;
    if (controller == null || positions.isEmpty) return;
    if (positions.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 14),
      );
      return;
    }
    var south = positions.first.latitude;
    var north = positions.first.latitude;
    var west = positions.first.longitude;
    var east = positions.first.longitude;
    for (final position in positions.skip(1)) {
      if (position.latitude < south) south = position.latitude;
      if (position.latitude > north) north = position.latitude;
      if (position.longitude < west) west = position.longitude;
      if (position.longitude > east) east = position.longitude;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        56,
      ),
    );
  }

  Future<void> _focusVendor(VendorModel vendor) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(vendor.latitude, vendor.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _VendorGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVendor?.id != widget.selectedVendor?.id &&
        widget.selectedVendor != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusVendor(widget.selectedVendor!),
      );
    } else if (oldWidget.vendors != widget.vendors ||
        oldWidget.pasarMalam != widget.pasarMalam) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitVisiblePlaces());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _SearchResultsPanel extends StatelessWidget {
  final String query;
  final List<VendorModel> vendors;
  final ValueChanged<VendorModel> onVendorTap;

  const _SearchResultsPanel({
    required this.query,
    required this.vendors,
    required this.onVendorTap,
  });

  @override
  Widget build(BuildContext context) {
    final initialChildSize = vendors.length <= 2 ? 0.34 : 0.46;

    return DraggableScrollableSheet(
      minChildSize: 0.22,
      initialChildSize: initialChildSize,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.22, 0.46, 0.86],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SheetDragHandle(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                query.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${vendors.length} result${vendors.length == 1 ? "" : "s"}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  sliver: SliverList.separated(
                    itemCount: vendors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _SearchResultCard(
                      vendor: vendors[index],
                      onTap: () => onVendorTap(vendors[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MapSheetSurface extends StatelessWidget {
  final Widget child;

  const _MapSheetSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 16,
      shadowColor: const Color(0x4D000000),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(top: false, child: child),
    );
  }
}

class _SheetTopBar extends StatelessWidget {
  final VoidCallback onDismiss;

  const _SheetTopBar({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const _SheetDragHandle(),
          Positioned(
            top: 5,
            right: 8,
            child: SizedBox.square(
              dimension: 36,
              child: IconButton(
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onDismiss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onTap;

  const _SearchResultCard({required this.vendor, required this.onTap});

  String get _summary {
    final description = vendor.description.trim();
    if (description.isNotEmpty) return description;
    if (vendor.heritageFoods.isNotEmpty) {
      return vendor.heritageFoods.take(2).join(', ');
    }
    if (vendor.address.isNotEmpty) return vendor.address;
    return vendor.state;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child:
                      vendor.coverImageUrl != null &&
                          vendor.coverImageUrl!.isNotEmpty
                      ? AppNetworkImage(
                          imageUrl: vendor.coverImageUrl,
                          fit: BoxFit.cover,
                          targetOptimizationWidth: 260,
                          errorWidget: const _VendorResultImageFallback(),
                        )
                      : const _VendorResultImageFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _OpenStatusPill(isOpen: vendor.isOpen),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBar(rating: vendor.averageRating, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${vendor.reviewCount} review${vendor.reviewCount == 1 ? "" : "s"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textHint),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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

class _OpenStatusPill extends StatelessWidget {
  final bool isOpen;

  const _OpenStatusPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? AppColors.success : AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VendorResultImageFallback extends StatelessWidget {
  const _VendorResultImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: AppColors.textSecondary,
          size: 28,
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.accentContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.nightlife_rounded,
                  color: AppColors.accentDark,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            market.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _OpenStatusPill(isOpen: market.isOpen),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _MarketMetaLine(
                      icon: Icons.place_outlined,
                      text: market.address.isNotEmpty
                          ? market.address
                          : market.state,
                    ),
                    const SizedBox(height: 5),
                    _MarketMetaLine(
                      icon: Icons.schedule_outlined,
                      text: _compactMarketHours(market.operatingHours),
                    ),
                    const SizedBox(height: 5),
                    _MarketMetaLine(
                      icon: Icons.storefront_outlined,
                      text: '${market.activeVendorCount} active stalls',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MarketMetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

String _compactMarketHours(List<PasarMalamOperatingHourModel> hours) {
  if (hours.isEmpty) return 'Opening hours unavailable';
  final displayed = hours
      .take(2)
      .map((hour) => '${hour.dayName.substring(0, 3)} ${hour.displayHours}')
      .join(' · ');
  return hours.length > 2 ? '$displayed · …' : displayed;
}

class _MarketHoursSection extends StatelessWidget {
  final List<PasarMalamOperatingHourModel> hours;

  const _MarketHoursSection({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Opening hours',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hours.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 26),
            child: Text(
              'Opening hours unavailable',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: hours
                  .map(
                    (hour) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hour.dayName.substring(0, 3)} · ${hour.displayHours}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _MarketSummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MarketSummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _MarketSummaryRating extends StatelessWidget {
  final ({double average, int reviews}) summary;

  const _MarketSummaryRating({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBar(rating: summary.average, size: 15, showLabel: false),
          const SizedBox(height: 3),
          Text(
            '${summary.average.toStringAsFixed(1)} · ${summary.reviews} review${summary.reviews == 1 ? '' : 's'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
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
  final ValueChanged<VendorModel>? onSelectVendor;

  const _PasarMalamPreviewSheet({
    required this.market,
    required this.vendors,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
    required this.onDismiss,
    this.onSelectVendor,
  });

  String get _location {
    final address = market.address.trim();
    return address.isNotEmpty ? address : market.state;
  }

  String get _description {
    final description = market.description.trim();
    if (description.isNotEmpty) return description;
    if (market.state.isNotEmpty) return 'Night market in ${market.state}.';
    return 'Local night market.';
  }

  ({double average, int reviews})? get _ratingSummary {
    final reviewedVendors = vendors.where((vendor) => vendor.reviewCount > 0);
    final reviews = reviewedVendors.fold<int>(
      0,
      (total, vendor) => total + vendor.reviewCount,
    );
    if (reviews == 0) return null;
    final ratingTotal = reviewedVendors.fold<double>(
      0,
      (total, vendor) => total + vendor.averageRating * vendor.reviewCount,
    );
    return (average: ratingTotal / reviews, reviews: reviews);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.34,
      initialChildSize: 0.52,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.34, 0.52, 0.86],
      builder: (context, scrollController) {
        return _MapSheetSurface(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetTopBar(onDismiss: onDismiss),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.festival_rounded,
                                    color: AppColors.accentDark,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    market.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _OpenStatusPill(isOpen: market.isOpen),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _location,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _MarketHoursSection(hours: market.operatingHours),
                            const SizedBox(height: 10),
                            Text(
                              _description,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      if (!isLoading && errorMessage == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: _MarketSummaryMetric(
                                  icon: Icons.storefront_outlined,
                                  label: 'Active heritage stalls',
                                  value: '${vendors.length}',
                                ),
                              ),
                              if (_ratingSummary != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MarketSummaryRating(
                                    summary: _ratingSummary!,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Active vendors',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            if (!isLoading && errorMessage == null)
                              Text(
                                '${vendors.length}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: AppColors.textHint,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.textHint,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            const Text('Vendors could not be loaded.'),
                            TextButton.icon(
                              onPressed: onRetry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (vendors.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No active vendors are listed for this night market.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList.separated(
                      itemCount: vendors.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 76, endIndent: 16),
                      itemBuilder: (_, index) {
                        final vendor = vendors[index];
                        return _MarketVendorRow(
                          vendor: vendor,
                          isSelectionMode: onSelectVendor != null,
                          onTap: () => onSelectVendor != null
                              ? onSelectVendor!(vendor)
                              : Navigator.pushNamed(
                                  context,
                                  AppRoutes.vendorDetail,
                                  arguments: vendor.id,
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MarketVendorRow extends StatelessWidget {
  final VendorModel vendor;
  final bool isSelectionMode;
  final VoidCallback onTap;

  const _MarketVendorRow({
    required this.vendor,
    required this.isSelectionMode,
    required this.onTap,
  });

  String get _summary {
    if (vendor.heritageFoods.isNotEmpty) {
      return vendor.heritageFoods.take(2).join(', ');
    }
    final description = vendor.description.trim();
    if (description.isNotEmpty) return description;
    if (vendor.businessType.isNotEmpty) return vendor.businessType;
    return vendor.state;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelectionMode
                  ? Icons.check_circle_outline_rounded
                  : Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
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
              color: _MapPageColors.darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _MapPageColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _MapPageColors.mediumGreen, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _MapPageColors.mediumGreen,
              ),
              style: const TextStyle(
                color: _MapPageColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              dropdownColor: _MapPageColors.background,
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
          color: selected ? _MapPageColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: _MapPageColors.darkGreen),
      ),
    );
  }
}

/// Vendor preview bottom sheet overlay.
class _VendorPreviewSheet extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onDismiss;
  final VoidCallback? onSelect;

  const _VendorPreviewSheet({
    required this.vendor,
    required this.onDismiss,
    this.onSelect,
  });

  String get _location {
    final address = vendor.address.trim();
    return address.isNotEmpty ? address : vendor.state;
  }

  String get _summary {
    final description = vendor.description.trim();
    if (description.isNotEmpty) return description;
    if (vendor.heritageFoods.isNotEmpty) {
      return vendor.heritageFoods.take(2).join(', ');
    }
    if (vendor.businessType.isNotEmpty) return vendor.businessType;
    return vendor.state;
  }

  @override
  Widget build(BuildContext context) {
    final selectionMode = onSelect != null;
    final minChildSize = selectionMode ? 0.26 : 0.28;
    final initialChildSize = selectionMode ? 0.36 : 0.42;
    final maxChildSize = selectionMode ? 0.58 : 0.78;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: double.infinity,
        child: DraggableScrollableSheet(
          // Let the sheet occupy only its current snap extent so the map stays
          // interactive above it instead of receiving an invisible full-screen
          // hit-test layer.
          expand: false,
          minChildSize: minChildSize,
          initialChildSize: initialChildSize,
          maxChildSize: maxChildSize,
          snap: true,
          shouldCloseOnMinExtent: false,
          snapSizes: selectionMode
              ? const [0.26, 0.36, 0.58]
              : const [0.28, 0.42, 0.78],
          builder: (context, scrollController) {
            return _MapSheetSurface(
              child: CustomScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _SheetTopBar(onDismiss: onDismiss)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 96,
                                          height: 84,
                                          child:
                                              vendor.coverImageUrl != null &&
                                                  vendor
                                                      .coverImageUrl!
                                                      .isNotEmpty
                                              ? AppNetworkImage(
                                                  imageUrl:
                                                      vendor.coverImageUrl,
                                                  fit: BoxFit.cover,
                                                  targetOptimizationWidth: 280,
                                                  errorWidget:
                                                      const _VendorResultImageFallback(),
                                                )
                                              : const _VendorResultImageFallback(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vendor.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            _OpenStatusPill(
                                              isOpen: vendor.isOpen,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.place_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _location,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      RatingBar(
                                        rating: vendor.averageRating,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${vendor.averageRating.toStringAsFixed(1)} '
                                          '(${vendor.reviewCount} review${vendor.reviewCount == 1 ? "" : "s"})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _summary,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          height: 1.35,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (selectionMode)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Select this vendor'),
                                onPressed: onSelect,
                              ),
                            )
                          else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.directions_rounded,
                                  size: 20,
                                ),
                                label: const Text('Get Directions'),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.routeNavigation,
                                  arguments: vendor.id,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('View Details'),
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.rate_review_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('View Reviews'),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.community,
                                      arguments: {
                                        'vendorId': vendor.id,
                                        'vendorName': vendor.name,
                                        'vendorAverageRating':
                                            vendor.averageRating,
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
