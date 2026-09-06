import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../Model/Repositories/HeritageExperience/heritage_media_model.dart';
import '../../Model/Services/media_playback_service.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

class HeritageVideoView extends StatefulWidget {
  final String mediaId;

  const HeritageVideoView({super.key, required this.mediaId});

  @override
  State<HeritageVideoView> createState() => _HeritageVideoViewState();
}

class _HeritageVideoViewState extends State<HeritageVideoView> {
  late final TiffinContentViewModel _vm;
  final MediaPlaybackService _playback = MediaPlaybackService();
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoFuture;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMedia());
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadMedia({bool showLoading = true}) async {
    await _vm.loadMedia(widget.mediaId, showLoading: showLoading);
    if (!mounted) return;
    final media = _vm.selectedMedia;
    if (media?.isVideo ?? false) {
      await _initializePlayer(media!);
    } else {
      await _disposePlayer();
    }
  }

  Future<void> _initializePlayer(HeritageMediaModel media) async {
    await _disposePlayer();
    final uri = Uri.tryParse(media.mediaUrl.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      setState(() => _playerError = 'This video URL is invalid.');
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    final initialization = controller.initialize();
    setState(() {
      _videoController = controller;
      _initializeVideoFuture = initialization;
      _playerError = null;
    });

    try {
      await initialization;
      if (!mounted || _videoController != controller) return;
      setState(() {});
    } catch (_) {
      if (!mounted || _videoController != controller) return;
      setState(() {
        _playerError =
            'This video could not be played in the app. Please try again.';
      });
    }
  }

  Future<void> _disposePlayer() async {
    final controller = _videoController;
    _videoController = null;
    _initializeVideoFuture = null;
    _playerError = null;
    await controller?.dispose();
  }

  Future<void> _openExternally(HeritageMediaModel media) async {
    try {
      await _playback.open(media.mediaUrl);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPlayer(controller: controller),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: _MediaColors.cream,
          appBar: AppBar(
            backgroundColor: _MediaColors.cream,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _MediaColors.green,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'Heritage Media',
              style: GoogleFonts.playfairDisplay(
                color: _MediaColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError
              ? ErrorStateWidget(
                  message: vm.errorMessage ?? 'Could not load this media.',
                  onRetry: () => vm.loadMedia(widget.mediaId),
                )
              : vm.selectedMedia == null
              ? RefreshableStateView(
                  onRefresh: () => _loadMedia(showLoading: false),
                  child: const EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: 'Media unavailable',
                    subtitle: 'This media item is no longer published.',
                  ),
                )
              : _buildContent(vm.selectedMedia!),
        ),
      ),
    );
  }

  Widget _buildContent(HeritageMediaModel selected) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // NEW: Universal heritage background
        IgnorePointer(
          child: Image.asset(
            'asset/image/heritage_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        // Keeps the universal background visible while maintaining readable text.
        IgnorePointer(
          child: ColoredBox(color: _MediaColors.cream.withValues(alpha: .18)),
        ),
        SafeArea(
          top: false,
          child: RefreshIndicator(
            color: _MediaColors.green,
            onRefresh: () => _loadMedia(showLoading: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              children: [
                const _MediaHeaderDivider(),
                const SizedBox(height: 26),
                _buildPlayer(selected),
                const SizedBox(height: 24),
                Text(
                  selected.title,
                  style: GoogleFonts.playfairDisplay(
                    color: _MediaColors.text,
                    fontSize: 31,
                    height: 1.16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 15),
                const _GoldDivider(),
                if (selected.caption?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 18),
                  Text(
                    selected.caption!,
                    style: GoogleFonts.nunito(
                      color: _MediaColors.text,
                      fontSize: 17,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (!selected.isVideo) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: () => _openExternally(selected),
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 22,
                      ),
                      label: const Text('Open media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _MediaColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer(HeritageMediaModel media) {
    if (!media.isVideo) {
      return _VideoThumbnail(media: media, onTap: () => _openExternally(media));
    }

    if (_playerError != null) {
      return _PlaybackErrorCard(
        message: _playerError!,
        thumbnailUrl: media.thumbnailUrl,
        onRetry: () => _initializePlayer(media),
        onOpenExternally: () => _openExternally(media),
      );
    }

    final controller = _videoController;
    final initialization = _initializeVideoFuture;
    if (controller == null || initialization == null) {
      return const _VideoLoadingCard();
    }

    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _VideoLoadingCard();
        }
        if (snapshot.hasError || !controller.value.isInitialized) {
          return _PlaybackErrorCard(
            message: 'This video could not be played in the app.',
            thumbnailUrl: media.thumbnailUrl,
            onRetry: () => _initializePlayer(media),
            onOpenExternally: () => _openExternally(media),
          );
        }
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: _VideoPlayerSurface(
            controller: controller,
            onFullscreen: _openFullscreen,
          ),
        );
      },
    );
  }
}

class _VideoPlayerSurface extends StatelessWidget {
  const _VideoPlayerSurface({
    required this.controller,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position > duration ? duration : value.position;
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      value.isPlaying ? controller.pause() : controller.play(),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: value.isPlaying ? 0 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .58),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (value.isBuffering)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              left: 12,
              right: 8,
              bottom: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .58),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 3, 4, 3),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => value.isPlaying
                            ? controller.pause()
                            : controller.play(),
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          colors: const VideoProgressColors(
                            playedColor: _MediaColors.gold,
                            bufferedColor: Color(0x99FFFFFF),
                            backgroundColor: Color(0x55FFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fullscreen',
                        visualDensity: VisualDensity.compact,
                        onPressed: onFullscreen,
                        icon: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _FullscreenVideoPlayer extends StatelessWidget {
  const _FullscreenVideoPlayer({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio > 0
                  ? controller.value.aspectRatio
                  : 16 / 9,
              child: _VideoPlayerSurface(
                controller: controller,
                onFullscreen: () => Navigator.maybePop(context),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton.filledTonal(
              tooltip: 'Exit fullscreen',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VideoLoadingCard extends StatelessWidget {
  const _VideoLoadingCard();

  @override
  Widget build(BuildContext context) => const AspectRatio(
    aspectRatio: 16 / 9,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
  );
}

class _PlaybackErrorCard extends StatelessWidget {
  const _PlaybackErrorCard({
    required this.message,
    required this.thumbnailUrl,
    required this.onRetry,
    required this.onOpenExternally,
  });

  final String message;
  final String? thumbnailUrl;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        image: thumbnailUrl?.trim().isNotEmpty ?? false
            ? DecorationImage(
                image: NetworkImage(thumbnailUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: .72),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(
                onPressed: onOpenExternally,
                child: const Text('Open in browser'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

abstract final class _MediaColors {
  static const green = Color(0xFF335C31);
  static const text = Color(0xFF283427);
  static const cream = Color(0xFFFAF7F0);
  static const gold = Color(0xFFD6A84B);
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.media, required this.onTap});

  final HeritageMediaModel media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: .18),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            image: media.thumbnailUrl?.trim().isNotEmpty ?? false
                ? DecorationImage(
                    image: NetworkImage(media.thumbnailUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: .32),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Center(
            child: Icon(
              media.isVideo
                  ? Icons.play_circle_fill_rounded
                  : Icons.open_in_new_rounded,
              size: 72,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

class _MediaHeaderDivider extends StatelessWidget {
  const _MediaHeaderDivider();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _MediaColors.green, thickness: .7)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: _MediaColors.gold,
          size: 14,
        ),
      ),
      Expanded(child: Divider(color: _MediaColors.green, thickness: .7)),
    ],
  );
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 37,
        child: Divider(color: _MediaColors.gold, thickness: 1),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: _MediaColors.gold,
          size: 13,
        ),
      ),
      SizedBox(
        width: 37,
        child: Divider(color: _MediaColors.gold, thickness: 1),
      ),
    ],
  );
}
