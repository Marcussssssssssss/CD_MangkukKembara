import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';

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
          backgroundColor: AppColors.background,
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
    const tiffinColor = AppColors.primary;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Hero header
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: tiffinColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tiffinColor, tiffinColor.withAlpha(180)],
                ),
              ),
              child: t.coverImageUrl != null
                  ? Image.network(t.coverImageUrl!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          Icons.kitchen_rounded,
                          size: 72,
                          color: Colors.white.withAlpha(220),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.stateCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
            title: Text(t.editionName, style: const TextStyle(fontSize: 14)),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edition title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  t.editionName,
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(t.state, style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  t.summary,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const Divider(indent: 16, endIndent: 16),

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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
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
    const accent = AppColors.primary;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
