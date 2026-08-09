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
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('🎉 Vote submitted!')),
              );
              _vm.clearVoteSuccess();
            });
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Artwork Entry')),
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
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [artColor, artColor.withAlpha(160)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: e.artworkUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: e.artworkUrl,
                        fit: BoxFit.cover,
                        targetOptimizationWidth: 1000,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ColoredBox(
                          color: Colors.black54,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              '${e.artworkTitle} · ${e.submitterName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        size: 64,
                        color: Colors.white.withAlpha(200),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.artworkTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'by ${e.submitterName}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _Section('Artist Statement', e.artistStatement),

                const SizedBox(height: 12),

                // Vote button
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
                const SizedBox(height: 32),
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
      padding: const EdgeInsets.only(bottom: 18),
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
