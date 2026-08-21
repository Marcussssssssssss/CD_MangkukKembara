import 'package:flutter/material.dart';

import '../../core/app_routes.dart';
import 'artwork_campaign_home_view.dart';
import 'heritage_community_style.dart';

/// Legacy campaign-detail route retained for deep links and existing callers.
/// It renders the same direct campaign experience as the Community tab.
class ArtworkCampaignDetailView extends StatelessWidget {
  final String campaignId;

  const ArtworkCampaignDetailView({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HeritageCommunityStyle.background,
      appBar: heritageCommunityAppBar(
        title: 'Campaign Artwork',
        leading: BackButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              navigator.pushReplacementNamed(AppRoutes.artworkCampaign);
            }
          },
        ),
      ),
      body: ArtworkCampaignPanel(campaignId: campaignId),
    );
  }
}
