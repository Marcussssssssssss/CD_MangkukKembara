import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';

/// B6. Artwork Meaning View.
class ArtworkMeaningView extends StatefulWidget {
  final String artworkId;
  const ArtworkMeaningView({super.key, required this.artworkId});

  @override
  State<ArtworkMeaningView> createState() => _ArtworkMeaningViewState();
}

class _ArtworkMeaningViewState extends State<ArtworkMeaningView> {
  late final TiffinContentViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadArtwork(widget.artworkId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Artwork Meaning')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError || vm.artwork == null
              ? ErrorStateWidget(
                  onRetry: () => vm.loadArtwork(widget.artworkId),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadArtwork(widget.artworkId, showLoading: false),
                  child: _buildContent(ctx, vm),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, TiffinContentViewModel vm) {
    final a = vm.artwork!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork hero
          Container(
            height: 360,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'asset/image/tiffin_background_green.png',
                  fit: BoxFit.cover,
                ),
                if (a.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    child: AppNetworkImage(
                      imageUrl: a.imageUrl,
                      fit: BoxFit.contain,
                      targetOptimizationWidth: 1000,
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        size: 64,
                        color: AppColors.primary.withAlpha(180),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.title,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section('Artwork Description', a.description),
                _Section('Artwork Meaning', a.artworkMeaning),
                _Section('Cultural Inspiration', a.culturalInspiration),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
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
