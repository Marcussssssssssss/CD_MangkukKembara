import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageExperience/heritage_media_model.dart';
import '../../Model/Services/media_playback_service.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../../core/app_colors.dart';
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
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Heritage Media')),
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
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadMedia(widget.mediaId, showLoading: false),
                  child: _buildContent(vm),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(TiffinContentViewModel vm) {
    final selected = vm.selectedMedia!;
    final related = vm.media.where((item) => item.id != selected.id).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: InkWell(
            onTap: () => _open(selected),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                image: selected.thumbnailUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(selected.thumbnailUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withAlpha(70),
                          BlendMode.darken,
                        ),
                      ),
              ),
              child: Icon(
                selected.isVideo
                    ? Icons.play_circle_fill_rounded
                    : Icons.open_in_new_rounded,
                size: 68,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(selected.title, style: Theme.of(context).textTheme.titleLarge),
        if (selected.durationLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            selected.durationLabel!,
            style: const TextStyle(color: AppColors.textHint),
          ),
        ],
        if (selected.caption?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(selected.caption!, style: const TextStyle(height: 1.5)),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _open(selected),
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(selected.isVideo ? 'Play video' : 'Open media'),
        ),
        if (related.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'More from this tiffin',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...related.map(
            (media) => Card(
              child: ListTile(
                leading: Icon(
                  media.isVideo
                      ? Icons.play_circle_outline
                      : Icons.image_outlined,
                ),
                title: Text(media.title),
                subtitle: media.durationLabel == null
                    ? null
                    : Text(media.durationLabel!),
                onTap: () => _open(media),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
