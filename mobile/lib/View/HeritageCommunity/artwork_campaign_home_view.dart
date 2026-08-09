import 'package:flutter/material.dart';
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

/// C5. Artwork Campaign Home View.
class ArtworkCampaignHomeView extends StatelessWidget {
  const ArtworkCampaignHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Heritage Artwork Campaign'),
        leading: const MapHomeButton(),
      ),
      body: const ArtworkCampaignPanel(),
    );
  }
}

/// Loads the single live campaign, or the newest completed campaign when no
/// campaign is live. [campaignId] keeps the legacy campaign-detail route usable.
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
              ? vm.featuredCampaign
              : vm.campaignById(widget.campaignId!);
          return ColoredBox(
            color: AppColors.background,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: vm.isLoading && campaign == null
                  ? const LoadingWidget(key: ValueKey('campaign-loading'))
                  : vm.hasError
                  ? ErrorStateWidget(
                      key: const ValueKey('campaign-error'),
                      message:
                          vm.errorMessage ??
                          'Artwork campaign could not be loaded.',
                      onRetry: _vm.retry,
                    )
                  : campaign == null
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
      (_) => _vm.loadCampaign(
        widget.campaign.id,
        loadArtworkEntries: !widget.campaign.isOpenSubmission,
      ),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await widget.onRefreshCampaign?.call();
    await _vm.loadCampaign(
      widget.campaign.id,
      showLoading: false,
      loadArtworkEntries: !widget.campaign.isOpenSubmission,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkVotingViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (vm.isLoading && vm.categories.isEmpty) {
            return const LoadingWidget();
          }
          if (vm.hasError) {
            return ErrorStateWidget(
              message: vm.errorMessage ?? 'Could not load this campaign.',
              onRetry: () => _vm.loadCampaign(
                widget.campaign.id,
                loadArtworkEntries: !widget.campaign.isOpenSubmission,
              ),
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
    ArtworkCampaignCategoryModel? selectedCategory;
    for (final category in vm.categories) {
      if (category.id == vm.selectedCategoryId) selectedCategory = category;
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _CampaignHeader(campaign: campaign)),
          if (vm.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: _CategorySelector(
                  selectedCategory: selectedCategory,
                  onTap: () => _showCategoryPicker(context, vm),
                ),
              ),
            ),
          if (campaign.isOpenSubmission && vm.selectedCategoryId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openSubmission(context, auth, vm),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Submit Artwork'),
                  ),
                ),
              ),
            ),
          if (!campaign.isOpenSubmission && vm.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'Sort artworks',
                      style: TextStyle(
                        color: AppColors.textSecondary,
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
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ..._buildCampaignSlivers(context, vm, auth),
        ],
      ),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    ArtworkVotingViewModel vm,
  ) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose category or state',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Artwork and results are shown for one category at a time.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: vm.categories.length,
                  itemBuilder: (_, index) {
                    final category = vm.categories[index];
                    final selected = category.id == vm.selectedCategoryId;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.location_on_outlined,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                      title: Text(
                        category.stateName.isEmpty
                            ? category.categoryName
                            : category.stateName,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      subtitle: category.stateName.isNotEmpty
                          ? Text(category.categoryName)
                          : null,
                      selected: selected,
                      selectedTileColor: AppColors.primaryContainer.withAlpha(
                        90,
                      ),
                      onTap: () => Navigator.pop(sheetContext, category.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedId == null || selectedId == vm.selectedCategoryId) return;
    if (widget.campaign.isOpenSubmission) {
      _vm.selectCategory(selectedId);
    } else {
      await _vm.loadEntries(selectedId);
    }
  }

  List<Widget> _buildCampaignSlivers(
    BuildContext context,
    ArtworkVotingViewModel vm,
    AuthViewModel auth,
  ) {
    if (vm.categories.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.category_outlined,
            title: 'No categories available',
            subtitle: 'Categories have not been published for this campaign.',
          ),
        ),
      ];
    }

    if (widget.campaign.isOpenSubmission) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.brush_outlined,
            title: 'Submissions are open',
            subtitle:
                'Choose a category above and submit your heritage artwork.',
          ),
        ),
      ];
    }

    if (vm.entries.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.image_search_outlined,
            title: 'No artwork designs yet',
            subtitle: 'No approved artwork is available in this category.',
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
              votingEnabled: widget.campaign.isVoting,
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

  Future<void> _openSubmission(
    BuildContext context,
    AuthViewModel auth,
    ArtworkVotingViewModel vm,
  ) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    if (!context.mounted || vm.selectedCategoryId == null) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.artworkSubmission,
      arguments: {
        'campaignId': widget.campaign.id,
        'categoryId': vm.selectedCategoryId!,
      },
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
      await _vm.loadEntries(entry.categoryId, showLoading: false);
    }
  }
}

class _CampaignHeader extends StatelessWidget {
  final ArtworkCampaignModel campaign;

  const _CampaignHeader({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final statusColor = campaign.isVoting
        ? AppColors.success
        : campaign.isOpenSubmission
        ? AppColors.primary
        : AppColors.accentDark;
    final statusBackground = campaign.isVoting
        ? AppColors.successLight
        : campaign.isOpenSubmission
        ? AppColors.primaryContainer
        : AppColors.accentContainer;
    final statusIcon = campaign.isVoting
        ? Icons.how_to_vote_rounded
        : campaign.isOpenSubmission
        ? Icons.add_photo_alternate_rounded
        : Icons.event_busy_rounded;
    final statusTitle = campaign.isVoting
        ? 'Voting Now'
        : campaign.isOpenSubmission
        ? 'Submissions Open'
        : 'Campaign Ended';
    return GestureDetector(
      onTap: () => _showCampaignDetails(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: campaign.isCompleted ? AppColors.accent : AppColors.divider,
            width: campaign.isCompleted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: statusBackground,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(190),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, size: 20, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 12, 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.info_outline_rounded,
                    color: statusColor,
                    size: 21,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCampaignDetails(BuildContext context) {
    final statusColor = campaign.isCompleted
        ? AppColors.accentDark
        : campaign.isVoting
        ? AppColors.success
        : AppColors.primary;
    final statusBackground = campaign.isCompleted
        ? AppColors.accentContainer
        : campaign.isVoting
        ? AppColors.successLight
        : AppColors.primaryContainer;
    final statusLabel = campaign.isCompleted
        ? 'Campaign Ended'
        : campaign.isVoting
        ? 'Voting Now'
        : 'Submissions Open';
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
    if (campaign.votingStartDate != null && campaign.votingEndDate != null) {
      return '${campaign.isCompleted ? 'Final voting period' : 'Voting period'}: ${_date(campaign.votingStartDate!)} – ${_date(campaign.votingEndDate!)}';
    }
    if (campaign.submissionStartDate != null &&
        campaign.submissionDeadline != null) {
      final label = campaign.isCompleted
          ? 'Final submission period'
          : 'Submission period';
      return '$label: ${_date(campaign.submissionStartDate!)} – ${_date(campaign.submissionDeadline!)}';
    }
    return null;
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _CategorySelector extends StatelessWidget {
  final ArtworkCampaignCategoryModel? selectedCategory;
  final VoidCallback onTap;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = selectedCategory;
    final primaryText = category == null
        ? 'Choose a category'
        : category.stateName.isEmpty
        ? category.categoryName
        : category.stateName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'Category / State',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (category != null && category.stateName.isNotEmpty)
                          Text(
                            category.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 108,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: entry.artworkUrl,
                    fit: BoxFit.cover,
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
                        color: Colors.black54,
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
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${entry.submitterName}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${entry.voteCount} votes',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
