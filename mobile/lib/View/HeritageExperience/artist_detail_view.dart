import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../Model/Repositories/HeritageExperience/artist_model.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

/// B5. Artist Detail View.
class ArtistDetailView extends StatefulWidget {
  final String artistId;
  const ArtistDetailView({super.key, required this.artistId});

  @override
  State<ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<ArtistDetailView> {
  late final TiffinContentViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadArtist(widget.artistId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Artist')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError || vm.artist == null
              ? ErrorStateWidget(
                  message: vm.errorMessage ?? 'Could not load this artist.',
                  onRetry: () => vm.loadArtist(widget.artistId),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadArtist(widget.artistId, showLoading: false),
                  child: _buildContent(context, vm.artist!),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ArtistModel artist) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  backgroundImage: artist.photoUrl == null
                      ? null
                      : NetworkImage(artist.photoUrl!),
                  child: artist.photoUrl == null
                      ? Text(
                          artist.fullName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  artist.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (artist.stageName != null &&
                    artist.stageName != artist.fullName)
                  Text(
                    artist.fullName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Biography', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            artist.biography,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (artist.websiteUrl != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.link_rounded, size: 16),
              label: Text(artist.websiteUrl!),
              onPressed: () async {
                final uri = Uri.tryParse(artist.websiteUrl!);
                if (uri == null || !await launchUrl(uri)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open this link.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
