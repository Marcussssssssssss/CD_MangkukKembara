import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';

/// Visual tokens for the tiffin experience detail presentation.
abstract final class _TiffinDetailColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  static const Color yellow = Color(0xFFF9B10E);
  static const Color softYellow = Color(0xFFFEF5E4);
  static const Color text = Color(0xFF283427);
}

/// B4. Tiffin Experience Overview — full heritage content for a tiffin.
class TiffinExperienceView extends StatefulWidget {
  final String tiffinId;
  const TiffinExperienceView({super.key, required this.tiffinId});

  @override
  State<TiffinExperienceView> createState() => _TiffinExperienceViewState();
}

class _TiffinExperienceViewState extends State<TiffinExperienceView> {
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
          backgroundColor: _TiffinDetailColors.background,
          body: vm.isLoading
              ? const LoadingSpinner(message: 'Loading heritage experience...')
              : vm.hasError || vm.tiffin == null
              ? ErrorStateWidget(onRetry: () => _vm.retry(widget.tiffinId))
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
    final t = vm.tiffin!;
    final backgroundAsset = _backgroundForState(t.state);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Hero header
        SliverAppBar(
          expandedHeight: 380,
          backgroundColor: _TiffinDetailColors.background,
          automaticallyImplyLeading: false,
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              if (t.coverImageUrl != null && t.coverImageUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _FullscreenTiffinImageView(
                        imageUrl: t.coverImageUrl!,
                        tiffinName: t.editionName,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
                    child: AppNetworkImage(
                      imageUrl: t.coverImageUrl,
                      fit: BoxFit.contain,
                      targetOptimizationWidth: 1200,
                    ),
                  ),
                )
              else
                Center(
                  child: Icon(
                    Icons.kitchen_rounded,
                    size: 96,
                    color: _TiffinDetailColors.darkGreen,
                  ),
                ),
              Positioned(
                top: MediaQuery.paddingOf(ctx).top + 12,
                left: 20,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _TiffinDetailColors.darkGreen,
                    ),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
              decoration: const BoxDecoration(
                color: _TiffinDetailColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Edition title
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(t.editionName, style: const TextStyle(
                  color: _TiffinDetailColors.darkGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: _TiffinDetailColors.mediumGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.state,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: _TiffinDetailColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Text(
                  t.summary,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: _TiffinDetailColors.text,
                  ),
                ),
              ),

              // Content cards
              if (vm.artwork != null)
                _ContentCard(
                  icon: Icons.palette_rounded,
                  title: 'Artwork',
                  subtitle: vm.artwork!.title,
                  description: vm.artwork!.description,
                  onTap: () => Navigator.pushNamed(
                    ctx,
                    AppRoutes.artworkMeaning,
                    arguments: vm.artwork!.id,
                  ),
                ),

              if (vm.artist != null)
                _ContentCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Artist',
                  subtitle: vm.artist!.displayName,
                  description: vm.artist!.biography.length > 120
                      ? '${vm.artist!.biography.substring(0, 120)}...'
                      : vm.artist!.biography,
                  onTap: () => Navigator.pushNamed(
                    ctx,
                    AppRoutes.artistDetail,
                    arguments: vm.artist!.id,
                  ),
                ),

              if (vm.stories.isNotEmpty)
                _ContentCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Heritage Story',
                  subtitle: vm.stories.first.title,
                  description: vm.stories.first.body.length > 120
                      ? '${vm.stories.first.body.substring(0, 120)}...'
                      : vm.stories.first.body,
                  onTap: () => Navigator.pushNamed(
                    ctx,
                    AppRoutes.heritageStory,
                    arguments: t.id,
                  ),
                ),

              _ContentCard(
                icon: Icons.restaurant_rounded,
                title: 'Food Origin & State',
                subtitle: 'Learn about the heritage foods',
                description:
                    'Discover the cultural significance of the foods featured in this tiffin edition.',
                onTap: () => Navigator.pushNamed(
                  ctx,
                  AppRoutes.foodOriginState,
                  arguments: t.id,
                ),
              ),

              if (vm.media.any((m) => m.isVideo))
                _ContentCard(
                  icon: Icons.play_circle_rounded,
                  title: 'Heritage Video',
                  subtitle: vm.media.firstWhere((m) => m.isVideo).title,
                  description:
                      vm.media.firstWhere((m) => m.isVideo).caption ?? '',
                  onTap: () => Navigator.pushNamed(
                    ctx,
                    AppRoutes.heritageVideo,
                    arguments: vm.media.firstWhere((m) => m.isVideo).id,
                  ),
                ),

              const SizedBox(height: 8),
            ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _backgroundForState(String state) {
    final normalized = state.toLowerCase();
    return normalized.contains('penang') ||
            normalized.contains('sarawak') ||
            normalized.contains('borneo')
        ? 'asset/image/tiffin_background_green.png'
        : 'asset/image/tiffin_background_yellow.png';
  }
}

class _FullscreenTiffinImageView extends StatelessWidget {
  final String imageUrl;
  final String tiffinName;

  const _FullscreenTiffinImageView({
    required this.imageUrl,
    required this.tiffinName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(tiffinName, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _ContentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: _TiffinDetailColors.softYellow,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _TiffinDetailColors.yellow),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _TiffinDetailColors.softYellow,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _TiffinDetailColors.darkGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _TiffinDetailColors.darkGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _TiffinDetailColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _TiffinDetailColors.text,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _TiffinDetailColors.darkGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
