import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import 'artwork_campaign_home_view.dart';

/// Legacy campaign-detail route retained for deep links and existing callers.
/// It renders the same direct campaign experience as the Community tab.
class ArtworkCampaignDetailView extends StatelessWidget {
  final String campaignId;

  const ArtworkCampaignDetailView({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0,
        leading: BackButton(
          color: AppColors.primary,
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              navigator.pushReplacementNamed(AppRoutes.artworkCampaign);
            }
          },
        ),
        title: const Text(
          'Campaign Artwork',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ArtworkCampaignPanel(campaignId: campaignId),
    );
  }
}
