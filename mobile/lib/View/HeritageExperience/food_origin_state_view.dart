import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageExperience/heritage_food_model.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

class FoodOriginStateView extends StatefulWidget {
  /// This route receives a tiffin ID and resolves its linked heritage food.
  final String foodId;

  const FoodOriginStateView({super.key, required this.foodId});

  @override
  State<FoodOriginStateView> createState() => _FoodOriginStateViewState();
}

class _FoodOriginStateViewState extends State<FoodOriginStateView> {
  late final TiffinContentViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadFoodForTiffin(widget.foodId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Food Origin & State')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError
              ? ErrorStateWidget(
                  message:
                      vm.errorMessage ?? 'Could not load this heritage food.',
                  onRetry: () => vm.loadFoodForTiffin(widget.foodId),
                )
              : vm.food == null
              ? RefreshableStateView(
                  onRefresh: () =>
                      vm.loadFoodForTiffin(widget.foodId, showLoading: false),
                  child: const EmptyStateWidget(
                    icon: Icons.rice_bowl_outlined,
                    title: 'Food story unavailable',
                    subtitle: 'No published food is linked to this tiffin.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadFoodForTiffin(widget.foodId, showLoading: false),
                  child: _buildContent(vm.food!),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(HeritageFoodModel food) {
    final subtitle = [
      food.categoryName,
      food.originStateName,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            image: food.imageUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(food.imageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(80),
                      BlendMode.darken,
                    ),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.rice_bowl_rounded,
                size: 56,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                food.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'Origin Summary',
          body: food.originSummary,
          emptyMessage: 'Origin details have not been published yet.',
        ),
        _Section(
          title: 'Cultural Significance',
          body: food.culturalSignificance,
          emptyMessage: 'Cultural notes have not been published yet.',
        ),
        if (food.originStateName != null)
          _Section(
            title: 'Origin State',
            body: food.originStateName,
            emptyMessage: 'Origin state unavailable.',
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.map_rounded),
          label: const Text('Browse Heritage Food Vendors'),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.treasureMap,
            (route) => false,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final String emptyMessage;

  const _Section({
    required this.title,
    required this.body,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body?.trim().isNotEmpty == true ? body! : emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
