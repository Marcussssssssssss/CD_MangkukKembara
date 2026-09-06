import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_campaign_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../../core/app_routes.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

/// Visual tokens for the refreshed artwork campaign experience.
abstract final class _CampaignColors {
  static const Color background = Color(0xFFF8FAF7);
  static const Color border = Color(0xFFE8ECE6);
  static const Color darkGreen = Color(0xFF1E3B2B);
  static const Color forestGreen = Color(0xFF234E35);
  static const Color textDark = Color(0xFF192A1E);
  static const Color textMuted = Color(0xFF7A887E);
  static const Color gold = Color(0xFFF4B333);
  static const Color darkGold = Color(0xFFDE9010);
  static const Color softGold = Color(0xFFFEF3D6);
  static const Color softYellow = Color(0xFFFEF5E4);
  static const Color paleMint = Color(0xFFE5EFE4);
}

/// C5. Artwork Campaign Home View.
class ArtworkCampaignHomeView extends StatelessWidget {
  final String? campaignId;

  const ArtworkCampaignHomeView({super.key, this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CampaignColors.background,
      appBar: AppBar(
        backgroundColor: _CampaignColors.background,
        foregroundColor: _CampaignColors.darkGreen,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: _CampaignColors.background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0,
        title: Text(
          'Campaign Artwork',
          style: GoogleFonts.playfairDisplay(
            color: _CampaignColors.darkGreen,
            fontWeight: FontWeight.w700,
            fontSize: 21,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          color: _CampaignColors.darkGreen,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.community);
            }
          },
        ),
      ),
      body: ArtworkCampaignPanel(campaignId: campaignId),
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
          final campaign = widget.campaignId != null
              ? vm.campaignById(widget.campaignId!)
              : (vm.campaigns.length == 1 ? vm.campaigns.first : null);
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
                  : (widget.campaignId == null && vm.campaigns.length > 1)
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
                      return _CampaignCard(
                        campaign: campaign,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.campaignDetail,
                          arguments: campaign.id,
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

class _CampaignCard extends StatelessWidget {
  final ArtworkCampaignModel campaign;
  final VoidCallback onTap;

  const _CampaignCard({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusLabel = campaign.isCompleted ? 'ENDED' : 'OPENING';
    final statusColor = campaign.isCompleted
        ? const Color(0xFF53605D)
        : const Color(0xFF986100);
    final statusBackground = campaign.isCompleted
        ? const Color(0xFFE5E9E7)
        : const Color(0xFFFFE4A8);
    return Container(
      height: 148,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD8DFD6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14335C31),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 112,
                    height: double.infinity,
                    child: ClipRect(
                      child: Transform.scale(
                        scale: 1.06,
                        child: Image.asset(
                          'asset/image/artwork_campaign_card.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 15, 10, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF14382D),
                                    fontSize: 15,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (campaign.description.trim().isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    campaign.description.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF7A858A),
                                      fontSize: 10.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 31,
                            height: 31,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5F0E1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF245C3C),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 7,
                top: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
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
              ..._buildCampaignSlivers(context, vm),
              SliverToBoxAdapter(
                child: SizedBox(height: showSubmitButton ? 96 : 32),
              ),
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
              label: const Text(
                'Submit Artwork',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: _CampaignColors.darkGreen,
              foregroundColor: Colors.white,
              elevation: 4,
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
            icon: Icons.palette_outlined,
            title: 'No artwork designs yet',
            subtitle: 'No approved artwork is available in this campaign.',
          ),
        ),
      ];
    }

    final campaign = widget.campaign;
    final isCompleted = campaign.isCompleted;
    final entries = vm.entries;
    final winnerEntry = entries.first;
    final otherEntries = entries.skip(1).toList();

    return [
      if (isCompleted) ...[
        // Section 1: Winning artwork
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Winning artwork',
                  style: TextStyle(
                    color: _CampaignColors.textDark,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Selected by the community',
                  style: TextStyle(
                    color: _CampaignColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _WinnerArtworkCard(
            entry: winnerEntry,
            onOpen: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.artworkVotingDetail,
                arguments: winnerEntry.id,
              );
              if (mounted) await _refresh();
            },
          ),
        ),
        if (otherEntries.isNotEmpty) ...[
          // Section 2: Other artwork
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                'Other artwork',
                style: TextStyle(
                  color: _CampaignColors.textDark,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = otherEntries[index];
                return _StandardArtworkCard(
                  entry: entry,
                  onOpen: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.artworkVotingDetail,
                      arguments: entry.id,
                    );
                    if (mounted) await _refresh();
                  },
                );
              },
              childCount: otherEntries.length,
            ),
          ),
        ],
      ] else ...[
        // Active Campaign: Featured submissions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured submissions',
                      style: TextStyle(
                        color: _CampaignColors.textDark,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${entries.length} ${entries.length == 1 ? "entry" : "entries"}',
                      style: const TextStyle(
                        color: _CampaignColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Community-voted artwork',
                  style: TextStyle(
                    color: _CampaignColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _WinnerArtworkCard(
            entry: winnerEntry,
            onOpen: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.artworkVotingDetail,
                arguments: winnerEntry.id,
              );
              if (mounted) await _refresh();
            },
          ),
        ),
        if (otherEntries.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                'Other artwork',
                style: TextStyle(
                  color: _CampaignColors.textDark,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = otherEntries[index];
                return _StandardArtworkCard(
                  entry: entry,
                  onOpen: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.artworkVotingDetail,
                      arguments: entry.id,
                    );
                    if (mounted) await _refresh();
                  },
                );
              },
              childCount: otherEntries.length,
            ),
          ),
        ],
      ],
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

class _CampaignHeader extends StatelessWidget {
  final ArtworkCampaignModel campaign;

  const _CampaignHeader({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: _CampaignColors.paleMint,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCampaignDetails(context),
          child: Stack(
            children: [
              // Top-right soft circular background watermarks
              Positioned(
                top: -26,
                right: -24,
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD6E4D5).withValues(alpha: 0.65),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: 36,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD6E4D5).withValues(alpha: 0.35),
                  ),
                ),
              ),
              // Info button on top-right
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: _CampaignColors.darkGreen,
                    size: 22,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 56, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CampaignColors.textDark,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD2DFD1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2EFE0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Color(0xFF2C5E3B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            campaign.isCompleted
                                ? 'Campaign completed'
                                : 'Campaign active',
                            style: const TextStyle(
                              color: Color(0xFF2C5E3B),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatDateRange(
                        campaign.submissionStartDate,
                        campaign.submissionDeadline,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF6E7C71),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
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

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      final fmt = DateFormat('d MMM yyyy');
      return '${fmt.format(start)} — ${fmt.format(end)}';
    }
    return '';
  }

  Future<void> _showCampaignDetails(BuildContext context) {
    final start = campaign.submissionStartDate;
    final end = campaign.submissionDeadline;
    final dateRangeSlash = (start != null && end != null)
        ? '${start.day}/${start.month}/${start.year} — ${end.day}/${end.month}/${end.year}'
        : 'Ongoing';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(bottomSheetContext).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D8D2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CAMPAIGN DETAILS',
                style: TextStyle(
                  color: Color(0xFF758278),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                campaign.title,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF192A1E),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF8E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF4DFB0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFFDE9010),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      campaign.isCompleted
                          ? 'Campaign completed'
                          : 'Campaign active',
                      style: const TextStyle(
                        color: Color(0xFF8B5E14),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'About this campaign',
                style: TextStyle(
                  color: Color(0xFF1E3123),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                campaign.description.trim().isNotEmpty
                    ? campaign.description.trim()
                    : 'A completed campaign for a Melaka-inspired heritage tiffin design.',
                style: const TextStyle(
                  color: Color(0xFF738176),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Color(0xFF234934),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campaign period',
                          style: TextStyle(
                            color: Color(0xFF7B887E),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateRangeSlash,
                          style: const TextStyle(
                            color: Color(0xFF1A3B2B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(bottomSheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E432B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter rendering the subtle geometric chevron pattern watermark.
class ChevronPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEEDBB2).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const double spacingX = 14;
    const double spacingY = 12;
    const double chevronW = 8;
    const double chevronH = 5;

    for (double y = 0; y <= size.height; y += spacingY) {
      for (double x = 0; x <= size.width; x += spacingX) {
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + chevronW / 2, y + chevronH)
          ..lineTo(x + chevronW, y);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _WinnerArtworkCard extends StatelessWidget {
  final ArtworkVotingEntryModel entry;
  final VoidCallback onOpen;

  const _WinnerArtworkCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _CampaignColors.gold, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper section: Centered Artwork Image
              Container(
                width: double.infinity,
                height: 220,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                alignment: Alignment.center,
                child: AppNetworkImage(
                  imageUrl: entry.artworkUrl,
                  fit: BoxFit.contain,
                  targetOptimizationWidth: 480,
                ),
              ),
              // Golden Divider line with overlapping Trophy & Champion badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 1.5,
                    width: double.infinity,
                    color: _CampaignColors.gold,
                  ),
                  Positioned(
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _CampaignColors.darkGold,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_outlined,
                            color: _CampaignColors.darkGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _CampaignColors.darkGold,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 2.5,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'CAMPAIGN CHAMPION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
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
              // Lower section: Details & Arrow Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.artworkTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _CampaignColors.darkGreen,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'by ${entry.submitterName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _CampaignColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFF8E5B16),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.voteCount} winning votes',
                                style: const TextStyle(
                                  color: Color(0xFF8E5B16),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 82,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: ChevronPatternPainter(),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: _CampaignColors.softGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFB77E20),
                              size: 24,
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
      ),
    );
  }
}

class _StandardArtworkCard extends StatelessWidget {
  final ArtworkVotingEntryModel entry;
  final VoidCallback onOpen;

  const _StandardArtworkCard({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _CampaignColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail with Rank badge
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: AppNetworkImage(
                          imageUrl: entry.artworkUrl,
                          fit: BoxFit.contain,
                          targetOptimizationWidth: 240,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _CampaignColors.forestGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${entry.currentRank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Middle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMMUNITY CREATION',
                        style: TextStyle(
                          color: Color(0xFF88968D),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.artworkTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _CampaignColors.darkGreen,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B5B3C),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.submitterName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7C8B80),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _CampaignColors.softYellow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFEAA21D),
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${entry.voteCount} votes',
                              style: const TextStyle(
                                color: Color(0xFF2E4837),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Arrow circle button
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF1E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF2B5B3C),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
