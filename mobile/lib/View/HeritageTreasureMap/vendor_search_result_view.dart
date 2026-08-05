import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/HeritageTreasureMap/vendor_search_view_model.dart';
import '../Widgets/vendor_card.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';

/// A2. Vendor Search Result View.
class VendorSearchResultView extends StatefulWidget {
  final String query;
  const VendorSearchResultView({super.key, required this.query});

  @override
  State<VendorSearchResultView> createState() => _VendorSearchResultViewState();
}

class _VendorSearchResultViewState extends State<VendorSearchResultView> {
  late final VendorSearchViewModel _vm;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _vm = VendorSearchViewModel();
    _ctrl = TextEditingController(text: widget.query);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.search(widget.query),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<VendorSearchViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: TextField(
              controller: _ctrl,
              autofocus: widget.query.isEmpty,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search vendors or foods...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(160)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              onChanged: vm.search,
            ),
            actions: [
              if (vm.hasActiveFilters)
                TextButton(
                  onPressed: vm.clearFilters,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Active filter chips
              if (vm.hasActiveFilters)
                Container(
                  color: AppColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      if (vm.selectedState != 'All States')
                        _FilterChip(
                          label: vm.selectedState,
                          onRemove: () => vm.setStateFilter('All States'),
                        ),
                      if (vm.selectedFoodCategory != 'All')
                        _FilterChip(
                          label: vm.selectedFoodCategory,
                          onRemove: () => vm.setFoodCategoryFilter('All'),
                        ),
                    ],
                  ),
                ),
              // State + category filter row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: AppConstants.malaysianStates
                      .take(6)
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              s,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: vm.selectedState == s,
                            onSelected: (_) => vm.setStateFilter(s),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: vm.selectedState == s
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              // Result count
              if (!vm.isLoading && !vm.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${vm.results.length} results',
                        style: Theme.of(ctx).textTheme.bodySmall,
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
                        selected: {vm.sort},
                        onSelectionChanged: (value) => vm.setSort(value.first),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
              // Results
              Expanded(
                child: vm.isLoading || vm.hasError
                    ? _buildResults(ctx, vm)
                    : RefreshIndicator(
                        onRefresh: () =>
                            vm.search(_ctrl.text, showLoading: false),
                        child: _buildResults(ctx, vm),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext ctx, VendorSearchViewModel vm) {
    if (vm.isLoading) return const LoadingWidget();
    if (vm.hasError) {
      return ErrorStateWidget(onRetry: () => vm.search(_ctrl.text));
    }
    if (vm.isEmpty) {
      return RefreshableStateView(
        onRefresh: () => vm.search(_ctrl.text, showLoading: false),
        child: const EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'No vendors found',
          subtitle: 'Try a different search term or remove filters.',
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemCount: vm.results.length,
      itemBuilder: (_, i) => VendorCard(
        vendor: vm.results[i],
        onTap: () => Navigator.pushNamed(
          ctx,
          AppRoutes.vendorDetail,
          arguments: vm.results[i].id,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
