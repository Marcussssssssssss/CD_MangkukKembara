import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/HeritageTreasureMap/route_navigation_view_model.dart';
import '../../core/app_colors.dart';
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.map_rounded,
            size: 84,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(vendor.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          vendor.address.isEmpty ? vendor.state : vendor.address,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          vm.destinationCoordinates,
          style: const TextStyle(color: AppColors.textHint),
        ),
        const SizedBox(height: 24),
        const Text(
          'Travel mode',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
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
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => _openDirections(vm),
          icon: const Icon(Icons.open_in_new_rounded),
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
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}
