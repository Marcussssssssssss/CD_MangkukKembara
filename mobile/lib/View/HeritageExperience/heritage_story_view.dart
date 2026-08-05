import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/empty_state_widget.dart';

/// B7. Heritage Story View with previous/next navigation.
class HeritageStoryView extends StatefulWidget {
  final String tiffinId;
  const HeritageStoryView({super.key, required this.tiffinId});

  @override
  State<HeritageStoryView> createState() => _HeritageStoryViewState();
}

class _HeritageStoryViewState extends State<HeritageStoryView> {
  late final TiffinContentViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadTiffin(widget.tiffinId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Heritage Story'),
            actions: [
              if (vm.stories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${vm.currentStoryIndex + 1} / ${vm.stories.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError
              ? ErrorStateWidget(onRetry: () => _vm.retry(widget.tiffinId))
              : vm.stories.isEmpty
              ? RefreshableStateView(
                  onRefresh: () =>
                      vm.loadTiffin(widget.tiffinId, showLoading: false),
                  child: const Center(
                    child: Text('No stories available for this tiffin.'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadTiffin(widget.tiffinId, showLoading: false),
                  child: _buildContent(ctx, vm),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, TiffinContentViewModel vm) {
    final story = vm.currentStory!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (vm.currentStoryIndex + 1) / vm.stories.length,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(story.title, style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Text(
                  story.body,
                  style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Navigation
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous'),
                  onPressed: vm.hasPreviousStory ? vm.prevStory : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(vm.hasNextStory ? 'Next' : 'Finish'),
                  onPressed: vm.hasNextStory
                      ? vm.nextStory
                      : () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
