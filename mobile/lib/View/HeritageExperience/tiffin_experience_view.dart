import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_routes.dart';
import '../../core/utils/cloudinary_utils.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';

/// Normalized (0.0–1.0) hotspot position for a single layer marker.
class _MarkerPosition {
  const _MarkerPosition(this.x, this.y);
  final double x;
  final double y;
}

/// Per-artwork hotspot coordinates for the three tiffin layers.
///
/// Each coordinate is a fraction of the **image** width/height, so
/// `(0.0, 0.0)` is the top-left corner of the artwork image and
/// `(1.0, 1.0)` is the bottom-right corner.
class _LayerHotspots {
  const _LayerHotspots({
    required this.layer1,
    required this.layer2,
    required this.layer3,
  });

  final _MarkerPosition layer1;
  final _MarkerPosition layer2;
  final _MarkerPosition layer3;

  /// Sensible default when a tiffin has no per-artwork hotspot data.
  static const _LayerHotspots fallback = _LayerHotspots(
    layer1: _MarkerPosition(0.10, 0.38),
    layer2: _MarkerPosition(0.90, 0.55),
    layer3: _MarkerPosition(0.10, 0.72),
  );

  /// Per-tiffin hotspot overrides.
  ///
  /// When a new tiffin artwork is added, define its layer positions here.
  /// Values are normalized to the image canvas (0.0–1.0).
  /// In future, these can be fetched from a `layer_markers` JSONB column
  /// in the `artworks` table.
  static const Map<String, _LayerHotspots> _perTiffin = {
    'HT0001': _LayerHotspots(  // Penang Street Flavours 2026
      layer1: _MarkerPosition(0.10, 0.38),
      layer2: _MarkerPosition(0.90, 0.55),
      layer3: _MarkerPosition(0.10, 0.75),
    ),
    'HT0002': _LayerHotspots(  // Melaka Peranakan Heritage 2026
      layer1: _MarkerPosition(0.10, 0.38),
      layer2: _MarkerPosition(0.90, 0.55),
      layer3: _MarkerPosition(0.10, 0.72),
    ),
    'HT0003': _LayerHotspots(  // East Coast Colours 2026
      layer1: _MarkerPosition(0.10, 0.38),
      layer2: _MarkerPosition(0.90, 0.55),
      layer3: _MarkerPosition(0.10, 0.72),
    ),
    'HT0004': _LayerHotspots(  // Borneo Traditions 2026
      layer1: _MarkerPosition(0.10, 0.38),
      layer2: _MarkerPosition(0.90, 0.55),
      layer3: _MarkerPosition(0.10, 0.72),
    ),
  };

  /// Look up hotspots for a given tiffin, falling back to defaults.
  static _LayerHotspots forTiffin(String? tiffinId) =>
      _perTiffin[tiffinId] ?? fallback;
}

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

class _TiffinExperienceViewState extends State<TiffinExperienceView>
    with SingleTickerProviderStateMixin {
  late final TiffinContentViewModel _vm;
  late final ScrollController _scrollController;
  late final AnimationController _storyEntranceController;
  final GlobalKey _learnMoreKey = GlobalKey();
  // ── NEW: keeps the stagger stable while the section remains visible. ──
  bool _storySectionIsActive = false;
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
        if ((progress != _scrollProgress || offset != _scrollOffset) &&
            mounted) {
          setState(() {
            _scrollProgress = progress;
            _scrollOffset = offset;
          });
        }
        _tryStartStoryEntrance();
      });
    _storyEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadTiffin(widget.tiffinId),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _storyEntranceController.dispose();
    super.dispose();
  }

  // ── NEW: repeatable story entrance using enter/exit hysteresis. ──
  void _tryStartStoryEntrance() {
    if (!mounted) return;
    final renderBox =
        _learnMoreKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null ||
        !renderBox.attached ||
        renderBox.size.height == 0) {
      return;
    }

    final sectionTop = renderBox.localToGlobal(Offset.zero).dy;
    final sectionBottom = sectionTop + renderBox.size.height;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final visibleHeight =
        (sectionBottom.clamp(0.0, viewportHeight) -
                sectionTop.clamp(0.0, viewportHeight))
            .clamp(0.0, renderBox.size.height);
    final visibleFraction = visibleHeight / renderBox.size.height;

    const enterThreshold = .22;
    const exitThreshold = .05;
    if (!_storySectionIsActive && visibleFraction >= enterThreshold) {
      _storySectionIsActive = true;
      _storyEntranceController.forward(from: 0);
    } else if (_storySectionIsActive && visibleFraction <= exitThreshold) {
      // Reset only after the section has almost entirely left the viewport.
      _storySectionIsActive = false;
      _storyEntranceController.reset();
    }
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
              tiffinId: t.id,
              state: t.state,
              imageUrl: t.coverImageUrl,
              onBack: () => Navigator.maybePop(ctx),
              onLayerOneTap: () => _showLayerDetails(ctx, vm, layerNumber: 1),
              onLayerTwoTap: () => _showLayerDetails(ctx, vm, layerNumber: 2),
              onLayerThreeTap: () => _showLayerDetails(ctx, vm, layerNumber: 3),
              onExploreTap: _scrollToLearnMore,
              scrollProgress: _scrollProgress,
              scrollOffset: _scrollOffset,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _LearnMorePanel(
            key: _learnMoreKey,
            vm: vm,
            entranceController: _storyEntranceController,
          ),
        ),
      ],
    );
  }

  // NEW: Smooth scroll to Unpack the Story
  void _scrollToLearnMore() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      MediaQuery.sizeOf(context).height,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openArtworkStory(
    BuildContext context,
    TiffinContentViewModel vm, {
    int storyLayer = 0,
  }) async {
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

  Future<void> _showLayerDetails(
    BuildContext context,
    TiffinContentViewModel vm, {
    required int layerNumber,
  }) async {
    final submissionId = vm.artwork?.sourceArtworkSubmissionId;
    if (submissionId == null || submissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layer details are not available yet.')),
      );
      return;
    }

    final entryFuture = ArtworkVotingViewModel().findEntryForArtworkSubmission(
      submissionId,
    );
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LayerDetailsSheet(
        layerNumber: layerNumber,
        entryFuture: entryFuture,
        onViewFullStory: (entry) {
          Navigator.pop(sheetContext);
          if (!context.mounted) return;
          Navigator.pushNamed(
            context,
            AppRoutes.artworkVotingDetail,
            arguments: {'entryId': entry.id, 'initialLayer': layerNumber},
          );
        },
      ),
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
    required this.tiffinId,
    required this.state,
    required this.imageUrl,
    required this.onBack,
    required this.onLayerOneTap,
    required this.onLayerTwoTap,
    required this.onLayerThreeTap,
    required this.onExploreTap,
    required this.scrollProgress,
    required this.scrollOffset,
  });

  final String backgroundAsset;
  final String tiffinName;
  final String tiffinId;
  final String state;
  final String? imageUrl;
  final VoidCallback onBack;
  final VoidCallback onLayerOneTap;
  final VoidCallback onLayerTwoTap;
  final VoidCallback onLayerThreeTap;
  final VoidCallback onExploreTap;
  final double scrollProgress;
  final double scrollOffset;

  @override
  State<_ExperienceHero> createState() => _ExperienceHeroState();
}

class _ExperienceHeroState extends State<_ExperienceHero>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _glowController;
  // NEW: Scroll indicator animation
  late final AnimationController _scrollHintController;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  Size? _intrinsicImageSize;
  String? _resolvedImageUrl;

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
    _scrollHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageDimensions();
  }

  @override
  void didUpdateWidget(covariant _ExperienceHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _intrinsicImageSize = null;
      _resolvedImageUrl = null;
      _resolveImageDimensions();
    }
  }

  void _resolveImageDimensions() {
    final optimizedUrl = CloudinaryUtils.getOptimizedUrl(
      widget.imageUrl,
      width: 1200,
    );
    if (optimizedUrl.isEmpty || optimizedUrl == _resolvedImageUrl) return;

    _removeImageStreamListener();
    _resolvedImageUrl = optimizedUrl;
    final stream = CachedNetworkImageProvider(
      optimizedUrl,
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((imageInfo, _) {
      final size = Size(
        imageInfo.image.width.toDouble(),
        imageInfo.image.height.toDouble(),
      );
      if (mounted && size != _intrinsicImageSize) {
        setState(() => _intrinsicImageSize = size);
      }
    });
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  void _removeImageStreamListener() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _imageStream = null;
    _imageStreamListener = null;
  }

  @override
  void dispose() {
    _removeImageStreamListener();
    _entranceController.dispose();
    _glowController.dispose();
    _scrollHintController.dispose();
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
                color: const Color(
                  0xFFFFC54D,
                ).withValues(alpha: .05 + (_glowController.value * .06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFFC54D,
                    ).withValues(alpha: .12 + (_glowController.value * .10)),
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
              opacity: CurvedAnimation(
                parent: _entranceController,
                curve: const Interval(0, .65, curve: Curves.easeOut),
              ),
              child: Transform.translate(
                offset: Offset(0, widget.scrollOffset * .58),
                child: Transform.scale(
                  scale: 1 - (widget.scrollProgress * .40),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .82, end: 1).animate(
                      CurvedAnimation(
                        parent: _entranceController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableSize = constraints.biggest;
                        final sourceSize = _intrinsicImageSize;

                        // Image dimensions not yet resolved — show image
                        // without markers to avoid misplacement.
                        if (sourceSize == null) {
                          return Center(
                            child: AppNetworkImage(
                              imageUrl: widget.imageUrl,
                              fit: BoxFit.contain,
                              targetOptimizationWidth: 1200,
                            ),
                          );
                        }

                        final renderedSize = applyBoxFit(
                          BoxFit.contain,
                          sourceSize,
                          availableSize,
                        ).destination;

                        return Center(
                          child: SizedBox.fromSize(
                            size: renderedSize,
                            child: OverflowBox(
                              maxWidth: renderedSize.width + 40,
                              maxHeight: renderedSize.height + 40,
                              child: SizedBox.fromSize(
                                size: renderedSize,
                                child: _TiffinImageWithLayerMarkers(
                                  imageUrl: widget.imageUrl,
                                  tiffinId: widget.tiffinId,
                                  entrance: _entranceController,
                                  onLayerOneTap: widget.onLayerOneTap,
                                  onLayerTwoTap: widget.onLayerTwoTap,
                                  onLayerThreeTap: widget.onLayerThreeTap,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
        // NEW: Hero content position adjustment
        Positioned(
          left: 24,
          right: 24,
          bottom: 112,
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
        // NEW: Scroll down indicator
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 14,
          child: Opacity(
            opacity: 1 - widget.scrollProgress,
            child: Center(
              child: InkWell(
                onTap: widget.onExploreTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NEW: Scroll indicator animation
                      AnimatedBuilder(
                        animation: _scrollHintController,
                        child: Column(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xD9FFFFFF),
                              size: 25,
                            ),
                            Transform.translate(
                              offset: Offset(0, -11),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xB3FFFFFF),
                                size: 25,
                              ),
                            ),
                          ],
                        ),
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _scrollHintController.value * 8),
                          child: child,
                        ),
                      ),
                      Text(
                        'Scroll down to explore',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TiffinImageWithLayerMarkers extends StatelessWidget {
  const _TiffinImageWithLayerMarkers({
    required this.imageUrl,
    required this.tiffinId,
    required this.entrance,
    required this.onLayerOneTap,
    required this.onLayerTwoTap,
    required this.onLayerThreeTap,
  });

  final String? imageUrl;
  final String tiffinId;
  final Animation<double> entrance;
  final VoidCallback onLayerOneTap;
  final VoidCallback onLayerTwoTap;
  final VoidCallback onLayerThreeTap;

  static const double _markerSize = 30;

  @override
  Widget build(BuildContext context) {
    final hotspots = _LayerHotspots.forTiffin(tiffinId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.fill,
                targetOptimizationWidth: 1200,
              ),
            ),
            _positionedMarker(
              size: size,
              pos: hotspots.layer1,
              number: 1,
              onTap: onLayerOneTap,
              delay: .45,
            ),
            _positionedMarker(
              size: size,
              pos: hotspots.layer2,
              number: 2,
              onTap: onLayerTwoTap,
              delay: .59,
            ),
            _positionedMarker(
              size: size,
              pos: hotspots.layer3,
              number: 3,
              onTap: onLayerThreeTap,
              delay: .73,
            ),
          ],
        );
      },
    );
  }

  Positioned _positionedMarker({
    required Size size,
    required _MarkerPosition pos,
    required int number,
    required VoidCallback onTap,
    required double delay,
  }) => Positioned(
    left: (size.width * pos.x) - (_markerSize / 2),
    top: (size.height * pos.y) - (_markerSize / 2),
    width: _markerSize,
    height: _markerSize,
    child: _AnimatedLayerMarker(
      number: number,
      onTap: onTap,
      entrance: entrance,
      delay: delay,
    ),
  );
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

class _LayerDetailsSheet extends StatelessWidget {
  const _LayerDetailsSheet({
    required this.layerNumber,
    required this.entryFuture,
    required this.onViewFullStory,
  });

  final int layerNumber;
  final Future<ArtworkVotingEntryModel?> entryFuture;
  final ValueChanged<ArtworkVotingEntryModel> onViewFullStory;

  String _meaningFor(ArtworkVotingEntryModel entry) => switch (layerNumber) {
    1 => entry.layer1Meaning,
    2 => entry.layer2Meaning,
    3 => entry.layer3Meaning,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
          child: FutureBuilder<ArtworkVotingEntryModel?>(
            future: entryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _LayerSheetLoading();
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const _LayerSheetUnavailable();
              }

              final entry = snapshot.data!;
              final meaning = _meaningFor(entry).trim();
              final culturalInspiration = entry.culturalInspiration.trim();
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DED3),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _LayerNumberBadge(number: layerNumber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TIFFIN ARTWORK',
                                style: GoogleFonts.nunito(
                                  color: _TiffinDetailColors.terracotta,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              Text(
                                'Layer $layerNumber',
                                style: GoogleFonts.playfairDisplay(
                                  color: _TiffinDetailColors.darkGreen,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _LayerDetailSection(
                      title: 'Layer meaning',
                      content: meaning.isEmpty
                          ? 'No layer meaning is available.'
                          : meaning,
                    ),
                    if (culturalInspiration.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _LayerDetailSection(
                        title: 'Cultural inspiration',
                        content: culturalInspiration,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => onViewFullStory(entry),
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: const Text('View full artwork story'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _TiffinDetailColors.darkGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LayerNumberBadge extends StatelessWidget {
  const _LayerNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: _TiffinDetailColors.mist,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      style: GoogleFonts.nunito(
        color: _TiffinDetailColors.darkGreen,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _LayerDetailSection extends StatelessWidget {
  const _LayerDetailSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _TiffinDetailColors.mist,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.nunito(
            color: _TiffinDetailColors.mediumGreen,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          content,
          style: GoogleFonts.nunito(
            color: _TiffinDetailColors.text,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _LayerSheetLoading extends StatelessWidget {
  const _LayerSheetLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 210,
    child: Center(
      child: CircularProgressIndicator(color: _TiffinDetailColors.darkGreen),
    ),
  );
}

class _LayerSheetUnavailable extends StatelessWidget {
  const _LayerSheetUnavailable();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 230,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: _TiffinDetailColors.mediumGreen,
          size: 36,
        ),
        const SizedBox(height: 12),
        Text(
          'Layer details are not available yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: _TiffinDetailColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _LearnMorePanel extends StatelessWidget {
  const _LearnMorePanel({
    super.key,
    required this.vm,
    required this.entranceController,
  });

  final TiffinContentViewModel vm;
  final AnimationController entranceController;

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
          Text(
            'LEARN MORE',
            style: GoogleFonts.nunito(
              color: _TiffinDetailColors.terracotta,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Unpack the story',
            style: GoogleFonts.playfairDisplay(
              color: _TiffinDetailColors.darkGreen,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          if (vm.artwork != null)
            _AnimatedStoryItem(
              index: 0,
              controller: entranceController,
              child: _GlassLearnCard(
                icon: Icons.palette_rounded,
                label: 'ARTWORK',
                title: vm.artwork!.title,
                onTap: () => _openArtwork(context, vm),
              ),
            ),
          if (vm.artist != null)
            _AnimatedStoryItem(
              index: 1,
              controller: entranceController,
              child: _GlassLearnCard(
                icon: Icons.person_outline_rounded,
                label: 'ARTIST',
                title: vm.artist!.displayName,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.artistDetail,
                  arguments: vm.artist!.id,
                ),
              ),
            ),
          if (vm.stories.isNotEmpty)
            _AnimatedStoryItem(
              index: 2,
              controller: entranceController,
              child: _GlassLearnCard(
                icon: Icons.menu_book_rounded,
                label: 'HERITAGE STORY',
                title: vm.stories.first.title,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.heritageStory,
                  arguments: tiffin.id,
                ),
              ),
            ),
          if (video != null)
            _AnimatedStoryItem(
              index: 3,
              controller: entranceController,
              child: _GlassLearnCard(
                icon: Icons.play_circle_rounded,
                label: 'HERITAGE VIDEO',
                title: video.title,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.heritageVideo,
                  arguments: video.id,
                ),
              ),
            ),
          _AnimatedStoryItem(
            index: 4,
            controller: entranceController,
            child: _GlassLearnCard(
              icon: Icons.restaurant_rounded,
              label: 'FOOD ORIGIN & STATE',
              title: 'Discover the heritage foods',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.foodOriginState,
                arguments: tiffin.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openArtwork(BuildContext context, TiffinContentViewModel vm) {
    final state = context.findAncestorStateOfType<_TiffinExperienceViewState>();
    state?._openArtworkStory(context, vm);
  }
}

// ── NEW: reusable one-shot, staggered left-to-right story-card entrance. ──
class _AnimatedStoryItem extends StatelessWidget {
  const _AnimatedStoryItem({
    required this.index,
    required this.controller,
    required this.child,
  });

  final int index;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = index * .10;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, start + .55, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-.32, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _GlassLearnCard extends StatelessWidget {
  const _GlassLearnCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _TiffinDetailColors.mist,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _TiffinDetailColors.yellow.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _TiffinDetailColors.darkGreen),
                ),
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
                          letterSpacing: 1,
                          color: _TiffinDetailColors.terracotta,
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _TiffinDetailColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _TiffinDetailColors.mediumGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
