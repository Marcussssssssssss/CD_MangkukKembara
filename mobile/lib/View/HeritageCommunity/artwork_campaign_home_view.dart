import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_campaign_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/map_home_button.dart';

/// Visual tokens for the refreshed artwork campaign experience.
abstract final class _CampaignColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
  static const Color mediumGreen = Color(0xFF61885B);
  static const Color yellow = Color(0xFFF9B10E);
  static const Color softYellow = Color(0xFFFEF5E4);
  static const Color text = Color(0xFF283427);
}

/// C5. Artwork Campaign Home View.
class ArtworkCampaignHomeView extends StatelessWidget {
  const ArtworkCampaignHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CampaignColors.background,
      appBar: AppBar(
        backgroundColor: _CampaignColors.background,
        foregroundColor: _CampaignColors.darkGreen,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: _CampaignColors.background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0,
        title: const Text(
          'Campaign Artwork',
          style: TextStyle(
            color: _CampaignColors.darkGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: const MapHomeButton(color: _CampaignColors.darkGreen),
      ),
      body: const ArtworkCampaignPanel(),
    );
  }
}

/// Shows all campaigns, or a single campaign's artworks for the detail route.
class ArtworkCampaignPanel extends StatefulWidget {
  final String? campaignId;

  const ArtworkCampaignPanel({super.key, this.campaignId});

  @override
  State<ArtworkCampaignPanel> createState() => _ArtworkCampaignPanelState();
}

class _ArtworkCampaignPanelState extends State<ArtworkCampaignPanel>
    with AutomaticKeepAliveClientMixin {
  late final ArtworkCampaignViewModel _vm;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _vm = ArtworkCampaignViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.loadCampaigns());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<ArtworkCampaignViewModel>(
        builder: (ctx, vm, _) {
          final campaign = widget.campaignId == null
              ? null
              : vm.campaignById(widget.campaignId!);
          return ColoredBox(
            color: _CampaignColors.background,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: vm.isLoading && vm.campaigns.isEmpty
                  ? const LoadingWidget(key: ValueKey('campaign-loading'))
                  : vm.hasError
                  ? ErrorStateWidget(
                      key: const ValueKey('campaign-error'),
                      message:
                          vm.errorMessage ??
                          'Artwork campaign could not be loaded.',
                      onRetry: _vm.retry,
                    )
                  : widget.campaignId == null && vm.campaigns.isEmpty
                  ? RefreshableStateView(
                      key: const ValueKey('campaign-empty'),
                      onRefresh: () => vm.loadCampaigns(showLoading: false),
                      child: const EmptyStateWidget(
                        icon: Icons.palette_outlined,
                        title: 'No campaign available',
                        subtitle:
                            'There is no live or completed artwork campaign yet.',
                      ),
                    )
                  : widget.campaignId == null
                  ? _CampaignList(
                      key: const ValueKey('campaign-list'),
                      campaigns: vm.campaigns,
                      onRefresh: () => vm.loadCampaigns(showLoading: false),
                    )
                  : campaign == null
                  ? RefreshableStateView(
                      key: const ValueKey('campaign-not-found'),
                      onRefresh: () => vm.loadCampaigns(showLoading: false),
                      child: const EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'Campaign not found',
                        subtitle: 'This artwork campaign is unavailable.',
                      ),
                    )
                  : ArtworkCampaignContent(
                      key: ValueKey(campaign.id),
                      campaign: campaign,
                      onRefreshCampaign: () =>
                          vm.loadCampaigns(showLoading: false),
                    ),
            ),
          );
        },
      ),
    );
  }
}

enum _CampaignFilter { opening, ended }

class _CampaignList extends StatefulWidget {
  final List<ArtworkCampaignModel> campaigns;
  final Future<void> Function() onRefresh;

  const _CampaignList({
    super.key,
    required this.campaigns,
    required this.onRefresh,
  });

  @override
  State<_CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<_CampaignList> {
  _CampaignFilter _filter = _CampaignFilter.opening;

  @override
  Widget build(BuildContext context) {
    final campaigns = widget.campaigns.where((campaign) {
      return switch (_filter) {
        _CampaignFilter.opening => campaign.isActive,
        _CampaignFilter.ended => campaign.isCompleted,
      };
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_CampaignFilter>(
              segments: const [
                ButtonSegment(
                  value: _CampaignFilter.opening,
                  label: Text('Opening'),
                  icon: Icon(Icons.lock_open_rounded),
                ),
                ButtonSegment(
                  value: _CampaignFilter.ended,
                  label: Text('Ended'),
                  icon: Icon(Icons.event_busy_rounded),
                ),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
        ),
        Expanded(
          child: campaigns.isEmpty
              ? RefreshableStateView(
                  onRefresh: widget.onRefresh,
                  child: EmptyStateWidget(
                    icon: _filter == _CampaignFilter.opening
                        ? Icons.palette_outlined
                        : Icons.history_rounded,
                    title: _filter == _CampaignFilter.opening
                        ? 'No opening campaigns'
                        : 'No ended campaigns',
                    subtitle: _filter == _CampaignFilter.opening
                        ? 'There are no artwork campaigns open right now.'
                        : 'Completed artwork campaigns will appear here.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: _CampaignColors.border),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.campaignDetail,
                            arguments: campaign.id,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        campaign.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                                if (campaign.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    campaign.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Shared direct campaign experience used by the Community tab and the legacy
/// campaign-detail route.
class ArtworkCampaignContent extends StatefulWidget {
  final ArtworkCampaignModel campaign;
  final Future<void> Function()? onRefreshCampaign;

  const ArtworkCampaignContent({
    super.key,
    required this.campaign,
    this.onRefreshCampaign,
  });

  @override
  State<ArtworkCampaignContent> createState() => _ArtworkCampaignContentState();
}

class _ArtworkCampaignContentState extends State<ArtworkCampaignContent> {
  late final ArtworkVotingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ArtworkVotingViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadCampaign(widget.campaign.id),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await widget.onRefreshCampaign?.call();
    await _vm.loadCampaign(widget.campaign.id, showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkVotingViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (vm.isLoading && vm.entries.isEmpty) {
            return const LoadingWidget();
          }
          if (vm.hasError) {
            return ErrorStateWidget(
              message: vm.errorMessage ?? 'Could not load this campaign.',
              onRetry: () => _vm.loadCampaign(widget.campaign.id),
            );
          }
          return _buildBody(ctx, vm, auth);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ArtworkVotingViewModel vm,
    AuthViewModel auth,
  ) {
    final campaign = widget.campaign;
    final showSubmitButton = campaign.canSubmit;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _CampaignHeader(campaign: campaign)),
              if (vm.entries.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        const Text(
                          'Sort artworks',
                          style: TextStyle(
                            color: _CampaignColors.darkGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Most Voted',
                              label: Text('Most voted'),
                            ),
                            ButtonSegment(value: 'New', label: Text('Newest')),
                          ],
                          selected: {vm.sort},
                          onSelectionChanged: (selection) =>
                              _vm.setSort(selection.first),
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? _CampaignColors.softYellow
                                  : _CampaignColors.background,
                            ),
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? _CampaignColors.yellow
                                  : _CampaignColors.darkGreen,
                            ),
                            side: const WidgetStatePropertyAll(
                              BorderSide(color: _CampaignColors.border),
                            ),
                            textStyle: const WidgetStatePropertyAll(
                              TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ..._buildCampaignSlivers(context, vm, auth),
              if (showSubmitButton)
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        ),
        if (showSubmitButton)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openSubmission(context, auth),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Submit Artwork'),
              backgroundColor: _CampaignColors.darkGreen,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCampaignSlivers(
    BuildContext context,
    ArtworkVotingViewModel vm,
    AuthViewModel auth,
  ) {
    if (vm.entries.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.image_search_outlined,
            title: 'No artwork designs yet',
            subtitle: 'No approved artwork is available in this campaign.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((_, index) {
            final entry = vm.entries[index];
            return _ArtworkEntryCard(
              entry: entry,
              votingEnabled: entry.isVotingOpen,
              onOpen: () => Navigator.pushNamed(
                context,
                AppRoutes.artworkVotingDetail,
                arguments: entry.id,
              ),
              onVote: () => _vote(context, auth, entry),
            );
          }, childCount: vm.entries.length),
        ),
      ),
    ];
  }

  Future<void> _openSubmission(BuildContext context, AuthViewModel auth) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    if (!context.mounted) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.artworkSubmission,
      arguments: {'campaignId': widget.campaign.id},
    );
  }

  Future<void> _vote(
    BuildContext context,
    AuthViewModel auth,
    ArtworkVotingEntryModel entry,
  ) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    if (entry.hasCurrentUserVoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already voted for this entry.')),
      );
      return;
    }
    final ok = await _vm.vote(entry.id, auth.currentUser!.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vote submitted!')));
      await _vm.refreshCampaign();
    }
  }
}

class _CampaignHeader extends StatelessWidget {
  final ArtworkCampaignModel campaign;

  const _CampaignHeader({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final statusColor = campaign.isCompleted
        ? _CampaignColors.yellow
        : _CampaignColors.mediumGreen;
    final statusIcon = campaign.isCompleted
        ? Icons.event_busy_rounded
        : Icons.how_to_vote_rounded;
    final statusTitle = campaign.isCompleted
        ? 'Campaign Completed'
        : campaign.canSubmit
        ? 'Submissions Open'
        : 'Active Campaign';
    return GestureDetector(
      onTap: () => _showCampaignDetails(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        height: 180,
        decoration: BoxDecoration(
          color: _CampaignColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _CampaignColors.yellow),
        ),
        // Keep the background artwork one pixel inside the outline. This
        // prevents it from bleeding into or softening the rounded corners.
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: .72,
                  child: Image.asset(
                    'asset/image/campaign_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: const BoxDecoration(
                            color: _CampaignColors.softYellow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, size: 22, color: statusColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          statusTitle,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            campaign.title,
                            style: const TextStyle(
                              color: _CampaignColors.darkGreen,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.info_outline_rounded,
                          color: _CampaignColors.yellow,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCampaignDetails(BuildContext context) {
    final statusColor = campaign.isCompleted
        ? AppColors.accentDark
        : AppColors.success;
    final statusBackground = campaign.isCompleted
        ? AppColors.accentContainer
        : AppColors.successLight;
    final statusLabel = campaign.isCompleted
        ? 'Campaign Completed'
        : campaign.canSubmit
        ? 'Submissions Open'
        : 'Active Campaign';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          campaign.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (campaign.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'About this campaign',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  campaign.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              if (_phaseDates(campaign) case final dates?) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          dates,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String? _phaseDates(ArtworkCampaignModel campaign) {
    if (campaign.submissionStartDate != null &&
        campaign.submissionDeadline != null) {
      return 'Campaign period: ${_date(campaign.submissionStartDate!)} - ${_date(campaign.submissionDeadline!)}';
    }
    return null;
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _ArtworkEntryCard extends StatelessWidget {
  final ArtworkVotingEntryModel entry;
  final bool votingEnabled;
  final VoidCallback onOpen;
  final VoidCallback onVote;

  const _ArtworkEntryCard({
    required this.entry,
    required this.votingEnabled,
    required this.onOpen,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: _CampaignColors.background,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _CampaignColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 124,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: entry.artworkUrl,
                    fit: BoxFit.contain,
                    targetOptimizationWidth: 300,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _CampaignColors.darkGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${entry.currentRank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.artworkTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _CampaignColors.darkGreen,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${entry.submitterName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _CampaignColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${entry.voteCount} votes',
                    style: const TextStyle(
                      color: _CampaignColors.darkGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (votingEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton(
                  onPressed: entry.hasCurrentUserVoted ? null : onVote,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(entry.hasCurrentUserVoted ? 'Voted' : 'Vote'),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _CampaignColors.darkGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
