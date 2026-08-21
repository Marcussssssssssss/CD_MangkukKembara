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
  static const Color background = Color(0xFFF9FBF7);
  static const Color border = Color(0xFFCCD6C8);
  static const Color darkGreen = Color(0xFF335C31);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.loadCampaign(widget.campaign.id);
    });
  }

  @override
  void didUpdateWidget(covariant ArtworkCampaignContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaign.id != widget.campaign.id) {
      _vm.loadCampaign(widget.campaign.id);
    }
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
                  child: _ArtworkGalleryHeader(
                    isCompleted: campaign.isCompleted,
                    sort: vm.sort,
                    onSortChanged: _vm.setSort,
                  ),
                ),
              ..._buildCampaignSlivers(context, vm),
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
              isWinner: widget.campaign.isCompleted && entry.currentRank == 1,
              onOpen: () async {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.artworkVotingDetail,
                  arguments: entry.id,
                );
                if (mounted) await _refresh();
              },
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
}

class _ArtworkGalleryHeader extends StatelessWidget {
  final bool isCompleted;
  final String sort;
  final ValueChanged<String> onSortChanged;

  const _ArtworkGalleryHeader({
    required this.isCompleted,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _CampaignColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 17,
              color: _CampaignColors.darkGreen,
            ),
            const SizedBox(width: 7),
            const Text(
              'Discover by',
              style: TextStyle(
                color: _CampaignColors.darkGreen,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Most Voted',
                  label: Text('Popular'),
                  icon: Icon(Icons.local_fire_department_rounded),
                ),
                ButtonSegment(
                  value: 'New',
                  label: Text('Fresh'),
                  icon: Icon(Icons.auto_awesome_rounded),
                ),
              ],
              selected: {sort},
              onSelectionChanged: (selection) => onSortChanged(selection.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? _CampaignColors.darkGreen
                      : Colors.white,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : _CampaignColors.darkGreen,
                ),
                iconSize: const WidgetStatePropertyAll(14),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignHeader extends StatelessWidget {
  final ArtworkCampaignModel campaign;

  const _CampaignHeader({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final statusIcon = campaign.isCompleted
        ? Icons.event_busy_rounded
        : Icons.how_to_vote_rounded;
    final statusTitle = campaign.isCompleted ? 'Campaign Completed' : 'Active';
    return GestureDetector(
      onTap: () => _showCampaignDetails(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28335C31),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'asset/image/tiffin_background_yellow.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF416F43), Color(0xFF203F2A)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFDF8EC),
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xCCFFFFFF),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x55FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: const Color(0xFFFDF8EC),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusTitle,
                          style: const TextStyle(
                            color: Color(0xFFFDF8EC),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
        : AppColors.success;
    final statusBackground = campaign.isCompleted
        ? AppColors.accentContainer
        : AppColors.successLight;
    final statusLabel = campaign.isCompleted ? 'Campaign Completed' : 'Active';
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
  final bool isWinner;
  final VoidCallback onOpen;

  const _ArtworkEntryCard({
    required this.entry,
    required this.isWinner,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isWinner) {
      return _WinnerArtworkCard(entry: entry, onOpen: onOpen);
    }

    return _StandardArtworkCard(entry: entry, onOpen: onOpen);
  }
}

class _StandardArtworkCard extends StatelessWidget {
  final ArtworkVotingEntryModel entry;
  final VoidCallback onOpen;

  const _StandardArtworkCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CampaignColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14335C31),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Row(
            children: [
              Container(
                width: 128,
                height: 142,
                color: const Color(0xFFF3F6F0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: AppNetworkImage(
                        imageUrl: entry.artworkUrl,
                        fit: BoxFit.contain,
                        targetOptimizationWidth: 360,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x26000000)],
                          stops: [0.68, 1],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _CampaignColors.darkGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 5),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${entry.currentRank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMMUNITY CREATION',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.artworkTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _CampaignColors.darkGreen,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.brush_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              entry.submitterName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: _CampaignColors.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _CampaignColors.softYellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 13,
                              color: _CampaignColors.yellow,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${entry.voteCount} votes',
                              style: const TextStyle(
                                color: _CampaignColors.darkGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFEEF3EC),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: _CampaignColors.darkGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerArtworkCard extends StatelessWidget {
  final ArtworkVotingEntryModel entry;
  final VoidCallback onOpen;

  const _WinnerArtworkCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF4B928);
    const deepGold = Color(0xFFC98308);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE69A), gold, deepGold, Color(0xFFFFD65C)],
        ),
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x45E6A315),
            blurRadius: 18,
            spreadRadius: 1,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            children: [
              const Positioned(
                right: -18,
                top: -28,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 112,
                  color: Color(0x14C98308),
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          imageUrl: entry.artworkUrl,
                          fit: BoxFit.contain,
                          targetOptimizationWidth: 300,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0x22000000)],
                              stops: [0.65, 1],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(7),
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [gold, deepGold],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'CAMPAIGN CHAMPION',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    letterSpacing: .7,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.artworkTitle,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: _CampaignColors.darkGreen,
                                  fontWeight: FontWeight.w900,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'by ${entry.submitterName}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: _CampaignColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 14,
                                color: deepGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.voteCount} winning votes',
                                style: const TextStyle(
                                  color: deepGold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.chevron_right_rounded, color: deepGold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
