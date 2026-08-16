import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';

/// C7. Artwork Voting Detail View.
class ArtworkVotingDetailView extends StatefulWidget {
  final String entryId;
  const ArtworkVotingDetailView({super.key, required this.entryId});

  @override
  State<ArtworkVotingDetailView> createState() =>
      _ArtworkVotingDetailViewState();
}

class _ArtworkVotingDetailViewState extends State<ArtworkVotingDetailView> {
  late final ArtworkVotingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ArtworkVotingViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadEntry(widget.entryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkVotingViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (vm.voteSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(const SnackBar(content: Text('Vote submitted!')));
              _vm.clearVoteSuccess();
            });
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Artwork')),
            body: vm.isLoading
                ? const LoadingSpinner()
                : vm.hasError || vm.selectedEntry == null
                ? ErrorStateWidget(
                    message: vm.errorMessage ?? 'Could not load this entry.',
                    onRetry: () => vm.loadEntry(widget.entryId),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        vm.loadEntry(widget.entryId, showLoading: false),
                    child: _buildContent(ctx, vm, auth),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext ctx,
    ArtworkVotingViewModel vm,
    AuthViewModel auth,
  ) {
    final e = vm.selectedEntry!;
    const artColor = AppColors.primary;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork hero
          Container(
            height: 360,
            width: double.infinity,
            color: AppColors.background,
            child: e.artworkUrl.isNotEmpty
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _FullscreenArtworkView(
                          imageUrl: e.artworkUrl,
                          title: e.artworkTitle,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      child: AppNetworkImage(
                        imageUrl: e.artworkUrl,
                        fit: BoxFit.contain,
                        targetOptimizationWidth: 1000,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.palette_rounded,
                      size: 64,
                      color: AppColors.primary.withAlpha(180),
                    ),
                  ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryContainer, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.artworkTitle,
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ARTWORK BY',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.submitterName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Rank + votes
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: artColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rank #${e.currentRank}',
                        style: TextStyle(
                          color: artColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.how_to_vote_rounded,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.voteCount} votes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _Section('Design Description', e.designDescription),
                _Section('Cultural Inspiration', e.culturalInspiration),
                _Section('Layer 1 Meaning', e.layer1Meaning),
                _Section('Layer 2 Meaning', e.layer2Meaning),
                _Section('Layer 3 Meaning', e.layer3Meaning, bottomPadding: 0),

                if (e.isVotingOpen) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: e.hasCurrentUserVoted
                            ? AppColors.successLight
                            : AppColors.primary,
                        foregroundColor: e.hasCurrentUserVoted
                            ? AppColors.success
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: Icon(
                        e.hasCurrentUserVoted
                            ? Icons.check_circle_rounded
                            : Icons.how_to_vote_rounded,
                      ),
                      label: Text(
                        e.hasCurrentUserVoted
                            ? 'You Voted for This Entry'
                            : 'Vote for This Artwork',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: vm.isVoting || e.hasCurrentUserVoted
                          ? null
                          : () async {
                              if (!auth.isLoggedIn) {
                                await Navigator.pushNamed(ctx, AppRoutes.login);
                                return;
                              }
                              await _vm.vote(e.id, auth.currentUser!.id);
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenArtworkView extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullscreenArtworkView({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final double bottomPadding;

  const _Section(this.title, this.body, {this.bottomPadding = 18});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
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
