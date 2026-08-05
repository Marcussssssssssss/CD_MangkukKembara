import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../Widgets/empty_state_widget.dart';

/// C9. Campaign Rankings View.
class CampaignRankingsView extends StatefulWidget {
  final String campaignId;
  const CampaignRankingsView({super.key, required this.campaignId});

  @override
  State<CampaignRankingsView> createState() => _CampaignRankingsViewState();
}

class _CampaignRankingsViewState extends State<CampaignRankingsView> {
  late final ArtworkVotingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ArtworkVotingViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadRankings(widget.campaignId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<ArtworkVotingViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Current Rankings')),
          body: vm.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : vm.hasError
              ? const Center(child: Text('Failed to load rankings.'))
              : RefreshIndicator(
                  onRefresh: () =>
                      vm.loadRankings(widget.campaignId, showLoading: false),
                  child: _buildRankings(ctx, vm),
                ),
        ),
      ),
    );
  }

  Widget _buildRankings(BuildContext ctx, ArtworkVotingViewModel vm) {
    return Column(
      children: [
        // Header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent, AppColors.accentLight],
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Rankings',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Updates in real-time as votes come in',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: vm.rankings.isEmpty
              ? RefreshableStateView(
                  onRefresh: () =>
                      vm.loadRankings(widget.campaignId, showLoading: false),
                  child: const Center(
                    child: Text('No rankings are available yet.'),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.rankings.length,
                  itemBuilder: (_, i) {
                    final r = vm.rankings[i];
                    Color rankColor = i == 0
                        ? const Color(0xFFFFD700)
                        : i == 1
                        ? const Color(0xFFC0C0C0)
                        : i == 2
                        ? const Color(0xFFCD7F32)
                        : AppColors.textSecondary;
                    const entryColor = AppColors.primary;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: i == 0
                            ? Border.all(
                                color: const Color(0xFFFFD700),
                                width: 2,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 80,
                            decoration: BoxDecoration(
                              color: entryColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${r.rank}',
                                style: TextStyle(
                                  color: i < 3 ? rankColor : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.artworkTitle,
                                  style: Theme.of(ctx).textTheme.titleSmall,
                                ),
                                Text(
                                  'by ${r.submitterName}',
                                  style: Theme.of(ctx).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Text(
                                  '${r.voteCount}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text(
                                  'votes',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
