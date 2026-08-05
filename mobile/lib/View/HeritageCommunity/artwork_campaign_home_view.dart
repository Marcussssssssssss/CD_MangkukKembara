import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/artwork_campaign_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/map_home_button.dart';

/// C5. Artwork Campaign Home View.
class ArtworkCampaignHomeView extends StatelessWidget {
  const ArtworkCampaignHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Heritage Artwork Campaigns'),
        leading: const MapHomeButton(),
      ),
      body: const ArtworkCampaignPanel(),
    );
  }
}

/// Reusable campaign page for the Community tab and the legacy named route.
class ArtworkCampaignPanel extends StatefulWidget {
  const ArtworkCampaignPanel({super.key});

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
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkCampaignViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => ColoredBox(
          color: AppColors.background,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: vm.isLoading
                ? const LoadingWidget(key: ValueKey('campaign-loading'))
                : vm.hasError
                ? ErrorStateWidget(
                    key: const ValueKey('campaign-error'),
                    message:
                        vm.errorMessage ??
                        'Artwork campaigns could not be loaded.',
                    onRetry: _vm.retry,
                  )
                : vm.isEmpty
                ? RefreshableStateView(
                    key: const ValueKey('campaign-empty'),
                    onRefresh: () => vm.loadCampaigns(showLoading: false),
                    child: const EmptyStateWidget(
                      icon: Icons.emoji_events_outlined,
                      title: 'No campaigns found',
                      subtitle: 'No artwork campaigns are currently published.',
                    ),
                  )
                : RefreshIndicator(
                    key: const ValueKey('campaign-content'),
                    onRefresh: () => vm.loadCampaigns(showLoading: false),
                    child: _buildBody(ctx, vm, auth),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext ctx,
    ArtworkCampaignViewModel vm,
    AuthViewModel auth,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        // Voting campaigns
        if (vm.votingCampaigns.isNotEmpty) ...[
          _SectionHeader('🗳️  Voting Active'),
          ...vm.votingCampaigns.map(
            (c) => _CampaignCard(
              campaign: c,
              auth: auth,
              onTap: () => Navigator.pushNamed(
                ctx,
                AppRoutes.campaignDetail,
                arguments: c.id,
              ),
            ),
          ),
        ],
        // Open submission campaigns
        if (vm.openSubmissionCampaigns.isNotEmpty) ...[
          _SectionHeader('🎨  Open for Submission'),
          ...vm.openSubmissionCampaigns.map(
            (c) => _CampaignCard(
              campaign: c,
              auth: auth,
              onTap: () => Navigator.pushNamed(
                ctx,
                AppRoutes.campaignDetail,
                arguments: c.id,
              ),
            ),
          ),
        ],
        // Completed campaigns
        if (vm.completedCampaigns.isNotEmpty) ...[
          _SectionHeader('✅  Completed'),
          ...vm.completedCampaigns.map(
            (c) => _CampaignCard(
              campaign: c,
              auth: auth,
              onTap: () => Navigator.pushNamed(
                ctx,
                AppRoutes.campaignDetail,
                arguments: c.id,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final ArtworkCampaignModel campaign;
  final AuthViewModel auth;
  final VoidCallback onTap;
  const _CampaignCard({
    required this.campaign,
    required this.auth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = campaign.isVoting
        ? AppColors.success
        : campaign.isOpenSubmission
        ? AppColors.primary
        : AppColors.textHint;
    final statusBg = campaign.isVoting
        ? AppColors.successLight
        : campaign.isOpenSubmission
        ? AppColors.primaryContainer
        : AppColors.surfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: campaign.isVoting
                      ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                      : campaign.isOpenSubmission
                      ? [AppColors.primary, AppColors.primaryDark]
                      : [const Color(0xFF757575), const Color(0xFF424242)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  campaign.isVoting
                      ? Icons.how_to_vote_rounded
                      : campaign.isOpenSubmission
                      ? Icons.brush_rounded
                      : Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          campaign.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${campaign.categoryCount} categories',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (campaign.submissionDeadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          campaign.isVoting &&
                                  campaign.votingStartDate != null &&
                                  campaign.votingEndDate != null
                              ? 'Voting: ${campaign.votingStartDate!.day}/${campaign.votingStartDate!.month}/${campaign.votingStartDate!.year} – ${campaign.votingEndDate!.day}/${campaign.votingEndDate!.month}/${campaign.votingEndDate!.year}'
                              : 'Submissions: ${campaign.submissionStartDate?.day ?? ''}/${campaign.submissionStartDate?.month ?? ''}/${campaign.submissionStartDate?.year ?? ''} – ${campaign.submissionDeadline!.day}/${campaign.submissionDeadline!.month}/${campaign.submissionDeadline!.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
