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
import '../Widgets/vendor_card.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';

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

  const TreasureMapView({super.key, this.selectionMode = false});

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
                  bottom: widget.selectionMode ? 0 : 64,
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
                  bottom: widget.selectionMode ? 0 : 64,
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
                onSubmitted: widget.selectionMode
                    ? null
                    : (q) => Navigator.pushNamed(
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

    return _VendorGoogleMap(
      // Vendors belonging to a Pasar Malam are accessed through the market
      // marker, so only standalone vendors receive their own map pin.
      vendors: vm.vendors,
      pasarMalam: vm.pasarMalam,
      showCurrentLocation: vm.canShowCurrentLocation,
      showPlaceSummary: !widget.selectionMode,
      onVendorTap: vm.showVendorPreview,
      onPasarMalamTap: vm.showPasarMalamPreview,
    );
  }
}

/// Interactive map backed by vendor and night-market coordinates in Supabase.
class _VendorGoogleMap extends StatefulWidget {
  final List<VendorModel> vendors;
  final List<PasarMalamModel> pasarMalam;
  final bool showCurrentLocation;
  final bool showPlaceSummary;
  final void Function(VendorModel) onVendorTap;
  final void Function(PasarMalamModel) onPasarMalamTap;

  const _VendorGoogleMap({
    required this.vendors,
    required this.pasarMalam,
    required this.showCurrentLocation,
    this.showPlaceSummary = true,
    required this.onVendorTap,
    required this.onPasarMalamTap,
  });

  @override
  State<_VendorGoogleMap> createState() => _VendorGoogleMapState();
}

class _VendorGoogleMapState extends State<_VendorGoogleMap> {
  GoogleMapController? _controller;

  static const _malaysia = CameraPosition(
    target: LatLng(4.2105, 101.9758),
    zoom: 5.4,
  );

  Set<Marker> get _markers => {
    ...widget.vendors.map(
      (vendor) => Marker(
        markerId: MarkerId('vendor_${vendor.id}'),
        position: LatLng(vendor.latitude, vendor.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndexInt: 2,
        infoWindow: InfoWindow(title: vendor.name, snippet: vendor.address),
        onTap: () => widget.onVendorTap(vendor),
      ),
    ),
    ...widget.pasarMalam.map(
      (market) => Marker(
        markerId: MarkerId('market_${market.id}'),
        position: LatLng(market.latitude, market.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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
            onMapCreated: (controller) {
              _controller = controller;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _fitVisiblePlaces(),
              );
            },
          ),
        ),
        if (widget.showPlaceSummary)
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
              child: Text(
                '${widget.vendors.length} places · '
                '${widget.pasarMalam.length} markets',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
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

  @override
  void didUpdateWidget(covariant _VendorGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendors != widget.vendors ||
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
  final ValueChanged<VendorModel>? onSelectVendor;
  final double bottom;

  const _PasarMalamPreviewSheet({
    required this.market,
    required this.vendors,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
    required this.onDismiss,
    this.onSelectVendor,
    this.bottom = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
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
                                trailing: Icon(
                                  onSelectVendor == null
                                      ? Icons.chevron_right_rounded
                                      : Icons.check_circle_outline_rounded,
                                ),
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
                ),
              ),
            ],
          ),
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
  final double bottom;

  const _VendorPreviewSheet({
    required this.vendor,
    required this.onDismiss,
    this.onSelect,
    this.bottom = 64,
  });

  @override
  Widget build(BuildContext context) {
    const coverColor = AppColors.primary;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
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
                child: onSelect != null
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Select this vendor'),
                          onPressed: onSelect,
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.directions_rounded,
                                size: 16,
                              ),
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
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                              ),
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
