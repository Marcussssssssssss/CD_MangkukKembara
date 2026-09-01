import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
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
  static const Color text = Color(0xFF283427);
  static const Color terracotta = Color(0xFFC85D3A);
  static const Color mist = Color(0xFFF3F7EF);
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
  late final ScrollController _scrollController;
  double _scrollProgress = 0;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    _scrollController = ScrollController()
      ..addListener(() {
        final progress = (_scrollController.offset / 220).clamp(0.0, 1.0);
        final offset = _scrollController.offset.clamp(0.0, 900.0);
        if ((progress != _scrollProgress || offset != _scrollOffset) && mounted) {
          setState(() {
            _scrollProgress = progress;
            _scrollOffset = offset;
          });
        }
      });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadTiffin(widget.tiffinId),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              : _buildContent(ctx, vm),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, TiffinContentViewModel vm) {
    final t = vm.tiffin!;
    final backgroundAsset = _backgroundForState(t.state);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height,
            child: _ExperienceHero(
              backgroundAsset: backgroundAsset,
              tiffinName: t.editionName,
              state: t.state,
              imageUrl: t.coverImageUrl,
              onBack: () => Navigator.maybePop(ctx),
              onLayerOneTap: () => _openArtworkStory(ctx, vm, storyLayer: 1),
              onLayerTwoTap: () => _openArtworkStory(ctx, vm, storyLayer: 2),
              onLayerThreeTap: () => _openArtworkStory(ctx, vm, storyLayer: 3),
              scrollProgress: _scrollProgress,
              scrollOffset: _scrollOffset,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _LearnMorePanel(vm: vm)),
      ],
    );
  }

  void _openLayerOne(BuildContext context, TiffinContentViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _TiffinLayerSheet(
        layerNumber: 1,
        items: [
          _LayerDestinationData(
            Icons.palette_rounded,
            'ARTWORK',
            vm.artwork?.title ?? 'Artwork story coming soon',
            _TiffinDetailColors.terracotta,
            vm.artwork == null
                ? null
                : () {
                    Navigator.pop(sheetContext);
                    _openArtworkStory(context, vm);
                  },
          ),
          _LayerDestinationData(
            Icons.person_outline_rounded,
            'ARTIST',
            vm.artist?.displayName ?? 'Artist profile coming soon',
            _TiffinDetailColors.mediumGreen,
            vm.artist == null
                ? null
                : () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.artistDetail,
                      arguments: vm.artist!.id,
                    );
                  },
          ),
        ],
      ),
    );
  }

  void _openLayerTwo(BuildContext context, TiffinContentViewModel vm) {
    final video = vm.media.where((media) => media.isVideo).firstOrNull;
    _showLayer(context, 2, [
      if (vm.stories.isNotEmpty)
        _LayerDestinationData(
          Icons.menu_book_rounded,
          'HERITAGE STORY',
          vm.stories.first.title,
          _TiffinDetailColors.mediumGreen,
          () => Navigator.pushNamed(
            context,
            AppRoutes.heritageStory,
            arguments: vm.tiffin!.id,
          ),
        ),
      if (video != null)
        _LayerDestinationData(
          Icons.play_circle_rounded,
          'HERITAGE VIDEO',
          video.title,
          const Color(0xFF456E9B),
          () => Navigator.pushNamed(
            context,
            AppRoutes.heritageVideo,
            arguments: video.id,
          ),
        ),
    ]);
  }

  void _openLayerThree(BuildContext context, TiffinContentViewModel vm) =>
      _showLayer(context, 3, [
        _LayerDestinationData(
          Icons.restaurant_rounded,
          'FOOD ORIGIN & STATE',
          'Discover the heritage foods',
          _TiffinDetailColors.yellow,
          () => Navigator.pushNamed(
            context,
            AppRoutes.foodOriginState,
            arguments: vm.tiffin!.id,
          ),
        ),
      ]);

  void _showLayer(
    BuildContext context,
    int layerNumber,
    List<_LayerDestinationData> items,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _TiffinLayerSheet(
        layerNumber: layerNumber,
        items: items
            .map(
              (item) => item.copyWith(
                onTap: item.onTap == null
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        item.onTap!();
                      },
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _openArtworkStory(
    BuildContext context,
    TiffinContentViewModel vm,
    {int storyLayer = 0}
  ) async {
    final submissionId = vm.artwork?.sourceArtworkSubmissionId;
    if (submissionId == null || submissionId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork Story is not available yet.')),
        );
      }
      return;
    }

    final entry = await ArtworkVotingViewModel().findEntryForArtworkSubmission(
      submissionId,
    );
    if (!context.mounted) return;
    if (entry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork Story is not available yet.')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.artworkVotingDetail,
      arguments: {'entryId': entry.id, 'initialLayer': storyLayer},
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

class _ExperienceHero extends StatefulWidget {
  const _ExperienceHero({
    required this.backgroundAsset,
    required this.tiffinName,
    required this.state,
    required this.imageUrl,
    required this.onBack,
    required this.onLayerOneTap,
    required this.onLayerTwoTap,
    required this.onLayerThreeTap,
    required this.scrollProgress,
    required this.scrollOffset,
  });

  final String backgroundAsset;
  final String tiffinName;
  final String state;
  final String? imageUrl;
  final VoidCallback onBack;
  final VoidCallback onLayerOneTap;
  final VoidCallback onLayerTwoTap;
  final VoidCallback onLayerThreeTap;
  final double scrollProgress;
  final double scrollOffset;

  @override
  State<_ExperienceHero> createState() => _ExperienceHeroState();
}

class _ExperienceHeroState extends State<_ExperienceHero>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0xB3305C42)],
              stops: [0, .48, 1],
            ),
          ),
        ),
        Positioned(
          right: -32,
          top: 75,
          child: Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) => Container(
              width: 286 + (_glowController.value * 18),
              height: 286 + (_glowController.value * 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC54D).withValues(
                  alpha: .05 + (_glowController.value * .06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC54D).withValues(
                      alpha: .12 + (_glowController.value * .10),
                    ),
                    blurRadius: 42 + (_glowController.value * 16),
                    spreadRadius: 5 + (_glowController.value * 5),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.imageUrl?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 48, 22, 72),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _entranceController, curve: const Interval(0, .65, curve: Curves.easeOut)),
              child: Transform.translate(
                offset: Offset(0, widget.scrollOffset * .58),
                child: Transform.scale(
                  scale: 1 - (widget.scrollProgress * .40),
                  child: ScaleTransition(
                  scale: Tween<double>(begin: .82, end: 1).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack)),
                  child: Stack(
                  alignment: Alignment.center,
                  children: [
                AppNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  targetOptimizationWidth: 1200,
                ),
                    Positioned(right: 310, top: 350, child: _AnimatedLayerMarker(number: 1, onTap: widget.onLayerOneTap, entrance: _entranceController, delay: .45)),
                    Positioned(right: 30, top: 418, child: _AnimatedLayerMarker(number: 2, onTap: widget.onLayerTwoTap, entrance: _entranceController, delay: .59)),
                    Positioned(right: 310, top: 486, child: _AnimatedLayerMarker(number: 3, onTap: widget.onLayerThreeTap, entrance: _entranceController, delay: .73)),
                  ],
                  ),
                ),
              ),
            ),
          ),
          )
        else
          const Center(
            child: Icon(Icons.kitchen_rounded, size: 110, color: Colors.white),
          ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 18,
          child: Material(
            color: Colors.white.withValues(alpha: .94),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Back',
              onPressed: widget.onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _TiffinDetailColors.darkGreen,
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 34,
          child: Opacity(
            opacity: 1,
            child: Transform.translate(
              offset: Offset(0, widget.scrollOffset * .50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _TiffinDetailColors.yellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'HERITAGE TASTE TRAIL',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: _TiffinDetailColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                widget.tiffinName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  height: 1.04,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: Color(0xFFFFD773),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.state,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LayerMarker extends StatelessWidget {
  const _LayerMarker({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .88),
    shape: const CircleBorder(),
    elevation: 3,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Text(
            '$number',
            style: GoogleFonts.nunito(
              color: _TiffinDetailColors.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AnimatedLayerMarker extends StatefulWidget {
  const _AnimatedLayerMarker({
    required this.number,
    required this.onTap,
    required this.entrance,
    required this.delay,
  });

  final int number;
  final VoidCallback onTap;
  final Animation<double> entrance;
  final double delay;

  @override
  State<_AnimatedLayerMarker> createState() => _AnimatedLayerMarkerState();
}

class _AnimatedLayerMarkerState extends State<_AnimatedLayerMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: widget.entrance,
      curve: Interval(widget.delay, 1, curve: Curves.easeOutBack),
    );
    return FadeTransition(
      opacity: entrance,
      child: AnimatedBuilder(
        animation: _floatController,
        child: _LayerMarker(number: widget.number, onTap: widget.onTap),
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -3 + (_floatController.value * 6)),
          child: child,
        ),
      ),
    );
  }
}

class _LearnMorePanel extends StatelessWidget {
  const _LearnMorePanel({required this.vm});

  final TiffinContentViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tiffin = vm.tiffin!;
    final video = vm.media.where((item) => item.isVideo).firstOrNull;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEARN MORE', style: GoogleFonts.nunito(color: _TiffinDetailColors.terracotta, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.3)),
          const SizedBox(height: 5),
          Text('Unpack the story', style: GoogleFonts.playfairDisplay(color: _TiffinDetailColors.darkGreen, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (vm.artwork != null) _GlassLearnCard(index: 0, icon: Icons.palette_rounded, label: 'ARTWORK', title: vm.artwork!.title, onTap: () => _openArtwork(context, vm)),
          if (vm.artist != null) _GlassLearnCard(index: 1, icon: Icons.person_outline_rounded, label: 'ARTIST', title: vm.artist!.displayName, onTap: () => Navigator.pushNamed(context, AppRoutes.artistDetail, arguments: vm.artist!.id)),
          if (vm.stories.isNotEmpty) _GlassLearnCard(index: 2, icon: Icons.menu_book_rounded, label: 'HERITAGE STORY', title: vm.stories.first.title, onTap: () => Navigator.pushNamed(context, AppRoutes.heritageStory, arguments: tiffin.id)),
          if (video != null) _GlassLearnCard(index: 3, icon: Icons.play_circle_rounded, label: 'HERITAGE VIDEO', title: video.title, onTap: () => Navigator.pushNamed(context, AppRoutes.heritageVideo, arguments: video.id)),
          _GlassLearnCard(index: 4, icon: Icons.restaurant_rounded, label: 'FOOD ORIGIN & STATE', title: 'Discover the heritage foods', onTap: () => Navigator.pushNamed(context, AppRoutes.foodOriginState, arguments: tiffin.id)),
        ],
      ),
    );
  }

  void _openArtwork(BuildContext context, TiffinContentViewModel vm) {
    final state = context.findAncestorStateOfType<_TiffinExperienceViewState>();
    state?._openArtworkStory(context, vm);
  }
}

class _GlassLearnCard extends StatelessWidget {
  const _GlassLearnCard({required this.index, required this.icon, required this.label, required this.title, required this.onTap});
  final int index;
  final IconData icon;
  final String label;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 600 + (index * 150)),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
      color: _TiffinDetailColors.mist,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: _TiffinDetailColors.yellow.withValues(alpha: .18), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: _TiffinDetailColors.darkGreen)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: _TiffinDetailColors.terracotta)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: _TiffinDetailColors.darkGreen)),
            ])),
            const Icon(Icons.arrow_forward_rounded, color: _TiffinDetailColors.mediumGreen),
          ]),
        ),
      ),
      ),
    ),
  );
}

class _TiffinLayerSheet extends StatelessWidget {
  const _TiffinLayerSheet({required this.layerNumber, required this.items});

  final int layerNumber;
  final List<_LayerDestinationData> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE6DA),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _TiffinDetailColors.mist,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: _TiffinDetailColors.terracotta,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIFFIN LAYER $layerNumber',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: _TiffinDetailColors.terracotta,
                        ),
                      ),
                      Text(
                        'What this layer carries',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: _TiffinDetailColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              'Open each layer to discover the people and cultural details behind this tiffin.',
              style: GoogleFonts.nunito(
                color: _TiffinDetailColors.text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 19),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('This layer is waiting to be discovered.'),
              )
            else
              for (var index = 0; index < items.length; index++) ...[
                _LayerDestination(
                  icon: items[index].icon,
                  label: items[index].label,
                  title: items[index].title,
                  color: items[index].color,
                  onTap: items[index].onTap,
                ),
                if (index < items.length - 1) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _LayerDestinationData {
  const _LayerDestinationData(
    this.icon,
    this.label,
    this.title,
    this.color,
    this.onTap,
  );

  final IconData icon;
  final String label;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  _LayerDestinationData copyWith({VoidCallback? onTap}) =>
      _LayerDestinationData(icon, label, title, color, onTap);
}

class _LayerDestination extends StatelessWidget {
  const _LayerDestination({
    required this.icon,
    required this.label,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .08),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .9,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: _TiffinDetailColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: onTap == null ? Colors.black26 : color,
            ),
          ],
        ),
      ),
    ),
  );
}
