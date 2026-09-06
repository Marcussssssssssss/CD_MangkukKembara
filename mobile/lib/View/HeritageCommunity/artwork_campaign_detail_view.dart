import 'package:flutter/material.dart';

import 'artwork_campaign_home_view.dart';

/// Legacy campaign-detail route retained for deep links and existing callers.
/// It renders the same direct campaign experience as the Community tab.
class ArtworkCampaignDetailView extends StatelessWidget {
  final String campaignId;

  const ArtworkCampaignDetailView({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return ArtworkCampaignHomeView(campaignId: campaignId);
  }
}
