import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'artwork_campaign_home_view.dart';

/// Legacy campaign-detail route retained for deep links and existing callers.
/// It renders the same direct campaign experience as the Community tab.
class ArtworkCategoryListView extends StatelessWidget {
  final String campaignId;

  const ArtworkCategoryListView({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Campaign Artwork')),
      body: ArtworkCampaignPanel(campaignId: campaignId),
    );
  }
}
