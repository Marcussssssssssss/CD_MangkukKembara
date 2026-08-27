import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/HeritageTreasureMap/route_navigation_view_model.dart';
import '../../core/app_colors.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

/// Opens real turn-by-turn directions to a vendor in Google Maps.
class RouteNavigationView extends StatefulWidget {
  final String vendorId;

  const RouteNavigationView({super.key, required this.vendorId});

  @override
  State<RouteNavigationView> createState() => _RouteNavigationViewState();
}

class _RouteNavigationViewState extends State<RouteNavigationView> {
  late final RouteNavigationViewModel _vm;

  String _travelModeLabel(TravelMode mode) => switch (mode) {
    TravelMode.driving => 'Drive',
    TravelMode.walking => 'Walk',
    TravelMode.transit => 'Transit',
  };

  @override
  void initState() {
    super.initState();
    _vm = RouteNavigationViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadVendor(widget.vendorId),
    );
  }

  Future<void> _openDirections(RouteNavigationViewModel vm) async {
    try {
      await vm.openDirections();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<RouteNavigationViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(vm.vendor?.name ?? 'Directions')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError || vm.vendor == null
              ? ErrorStateWidget(
                  message:
                      vm.errorMessage ??
                      'Could not load this vendor. Please try again.',
                  onRetry: () => vm.loadVendor(widget.vendorId),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadVendor(widget.vendorId, showLoading: false),
                  child: _buildContent(vm),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(RouteNavigationViewModel vm) {
    final vendor = vm.vendor!;
    final selectedModeLabel = _travelModeLabel(vm.travelMode);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          height: 164,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child:
              vendor.coverImageUrl != null && vendor.coverImageUrl!.isNotEmpty
              ? AppNetworkImage(
                  imageUrl: vendor.coverImageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  targetOptimizationWidth: 1200,
                  errorWidget: const _RouteCoverPlaceholder(),
                )
              : const _RouteCoverPlaceholder(),
        ),
        const SizedBox(height: 14),
        Text(vendor.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          vendor.address.isEmpty ? vendor.state : vendor.address,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                vm.destinationCoordinates,
                style: const TextStyle(color: AppColors.textHint),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Travel mode',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Selected: $selectedModeLabel',
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModeButton(
                    icon: Icons.directions_car_rounded,
                    label: 'Drive',
                    selected: vm.travelMode == TravelMode.driving,
                    onTap: () => vm.setTravelMode(TravelMode.driving),
                  ),
                  _ModeButton(
                    icon: Icons.directions_walk_rounded,
                    label: 'Walk',
                    selected: vm.travelMode == TravelMode.walking,
                    onTap: () => vm.setTravelMode(TravelMode.walking),
                  ),
                  _ModeButton(
                    icon: Icons.directions_transit_rounded,
                    label: 'Transit',
                    selected: vm.travelMode == TravelMode.transit,
                    onTap: () => vm.setTravelMode(TravelMode.transit),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            elevation: 3,
            shadowColor: AppColors.primary.withAlpha(80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => _openDirections(vm),
          icon: const Icon(Icons.directions_rounded, size: 21),
          label: const Text('Open directions in Google Maps'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Distance, duration, live traffic, and turn-by-turn routing are '
          'calculated by Google Maps from your current location.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _RouteCoverPlaceholder extends StatelessWidget {
  const _RouteCoverPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.primaryContainer,
    child: Center(
      child: Icon(Icons.map_rounded, size: 84, color: AppColors.primary),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.textOnPrimary,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
        width: selected ? 1.5 : 1,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? AppColors.textOnPrimary : AppColors.primary,
      ),
      label: Text(label),
    );
  }
}
