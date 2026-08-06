import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/empty_state_widget.dart';

/// C6. Campaign Category List / Artwork Entry List / Vote View.
class ArtworkCategoryListView extends StatefulWidget {
  final String campaignId;
  const ArtworkCategoryListView({super.key, required this.campaignId});

  @override
  State<ArtworkCategoryListView> createState() =>
      _ArtworkCategoryListViewState();
}

class _ArtworkCategoryListViewState extends State<ArtworkCategoryListView> {
  late final ArtworkVotingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ArtworkVotingViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadCampaign(widget.campaignId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkVotingViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Campaign Artwork'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  ctx,
                  AppRoutes.campaignRankings,
                  arguments: widget.campaignId,
                ),
                child: const Text(
                  'Rankings',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          body: vm.isLoading
              ? const LoadingWidget()
              : vm.hasError
              ? ErrorStateWidget(
                  message: vm.errorMessage ?? 'Could not load this campaign.',
                  onRetry: () => _vm.loadCampaign(widget.campaignId),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadCampaign(widget.campaignId, showLoading: false),
                  child: _buildBody(ctx, vm, auth),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext ctx,
    ArtworkVotingViewModel vm,
    AuthViewModel auth,
  ) {
    return Column(
      children: [
        if (vm.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: vm.selectedCategoryId,
              decoration: const InputDecoration(labelText: 'State category'),
              items: vm.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        '${category.categoryName} · ${category.stateName}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) _vm.loadEntries(value);
              },
            ),
          ),
        // Sort chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['Most Voted', 'New']
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      selected: vm.sort == s,
                      onSelected: (_) => _vm.setSort(s),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: vm.sort == s
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: vm.entries.isEmpty
              ? RefreshableStateView(
                  onRefresh: () =>
                      vm.loadCampaign(widget.campaignId, showLoading: false),
                  child: const Center(
                    child: Text('No artwork entries are available.'),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: vm.entries.length,
                  itemBuilder: (_, i) {
                    final entry = vm.entries[i];
                    const entryColor = AppColors.primary;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          ctx,
                          AppRoutes.artworkVotingDetail,
                          arguments: entry.id,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            // Rank badge
                            Container(
                              width: 64,
                              height: 90,
                              decoration: BoxDecoration(
                                color: entryColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '#${entry.currentRank}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Icon(
                                    Icons.how_to_vote_rounded,
                                    color: Colors.white.withAlpha(200),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.artworkTitle,
                                      style: Theme.of(ctx).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'by ${entry.submitterName}',
                                      style: Theme.of(ctx).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.how_to_vote_rounded,
                                          size: 14,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${entry.voteCount} votes',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Vote button
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!auth.isLoggedIn) {
                                    await Navigator.pushNamed(
                                      ctx,
                                      AppRoutes.login,
                                    );
                                    return;
                                  }
                                  if (entry.hasCurrentUserVoted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'You already voted for this entry.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final ok = await _vm.vote(
                                    entry.id,
                                    auth.currentUser!.id,
                                  );
                                  if (!ctx.mounted) return;
                                  if (ok) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vote submitted! 🎉'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: entry.hasCurrentUserVoted
                                      ? AppColors.successLight
                                      : AppColors.primary,
                                  foregroundColor: entry.hasCurrentUserVoted
                                      ? AppColors.success
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  entry.hasCurrentUserVoted ? 'Voted' : 'Vote',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
