import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadMedia(widget.mediaId),
    );
  }

  Future<void> _open(HeritageMediaModel media) async {
    try {
      await _playback.open(media.mediaUrl);
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
                  onRefresh: () =>
                      vm.loadMedia(widget.mediaId, showLoading: false),
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
            onRefresh: () => _vm.loadMedia(widget.mediaId, showLoading: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              children: [
                const _MediaHeaderDivider(),
                const SizedBox(height: 26),
                _VideoThumbnail(
                  media: selected,
                  onTap: () => _open(selected),
                ),
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
                const SizedBox(height: 30),
                SizedBox(
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () => _open(selected),
                    icon: Icon(
                      selected.isVideo
                          ? Icons.play_arrow_rounded
                          : Icons.open_in_new_rounded,
                      size: 22,
                    ),
                    label: Text(selected.isVideo ? 'Play video' : 'Open media'),
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
            ),
          ),
        ),
      ],
    );
  }
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
        child: Icon(Icons.auto_awesome_rounded, color: _MediaColors.gold, size: 14),
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
      SizedBox(width: 37, child: Divider(color: _MediaColors.gold, thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.auto_awesome_rounded, color: _MediaColors.gold, size: 13),
      ),
      SizedBox(width: 37, child: Divider(color: _MediaColors.gold, thickness: 1)),
    ],
  );
}
