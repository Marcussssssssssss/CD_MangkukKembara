import 'package:flutter/material.dart';

// Module A — Heritage Treasure Map
import '../View/HeritageTreasureMap/treasure_map_view.dart';
import '../View/HeritageTreasureMap/vendor_search_result_view.dart';
import '../View/HeritageTreasureMap/vendor_detail_view.dart';
import '../View/HeritageTreasureMap/route_navigation_view.dart';

// Module B — Heritage Experience
import '../View/HeritageExperience/heritage_experience_home_view.dart';
import '../View/HeritageExperience/qr_scanner_view.dart';
import '../View/HeritageExperience/scan_result_view.dart';
import '../View/HeritageExperience/tiffin_experience_view.dart';
import '../View/HeritageExperience/artist_detail_view.dart';
import '../View/HeritageExperience/artwork_meaning_view.dart';
import '../View/HeritageExperience/heritage_story_view.dart';
import '../View/HeritageExperience/food_origin_state_view.dart';
import '../View/HeritageExperience/heritage_video_view.dart';
import '../Model/Repositories/HeritageExperience/qr_scan_result_model.dart';

// Module C — Heritage Community
import '../View/HeritageCommunity/community_home_view.dart';
import '../View/HeritageCommunity/community_search_view.dart';
import '../View/HeritageCommunity/post_detail_view.dart';
import '../View/HeritageCommunity/create_post_view.dart';
import '../View/HeritageCommunity/artwork_campaign_home_view.dart';
import '../View/HeritageCommunity/artwork_category_list_view.dart';
import '../View/HeritageCommunity/artwork_voting_detail_view.dart';
import '../View/HeritageCommunity/artwork_submission_view.dart';
import '../View/HeritageCommunity/artwork_submission_success_view.dart';
import '../View/HeritageCommunity/campaign_rankings_view.dart';

// Module D — Account Management
import '../View/AccountManagement/guest_account_view.dart';
import '../View/AccountManagement/login_view.dart';
import '../View/AccountManagement/register_view.dart';
import '../View/AccountManagement/forgot_password_view.dart'; // also contains ChangePasswordView
import '../View/AccountManagement/profile_view.dart';
import '../View/AccountManagement/edit_profile_view.dart';
import '../View/AccountManagement/email_verification_view.dart';

/// All named route strings in the application.
abstract final class AppRoutes {
  // ── Module A ─────────────────────────────────────────────────────────────────
  static const String treasureMap = '/';
  static const String vendorSearch = '/vendor-search';
  static const String vendorDetail = '/vendor-detail';
  static const String routeNavigation = '/route-navigation';

  // ── Module B ─────────────────────────────────────────────────────────────────
  static const String heritageExperience = '/heritage-experience';
  static const String qrScanner = '/qr-scanner';
  static const String scanResult = '/scan-result';
  static const String tiffinExperience = '/tiffin-experience';
  static const String artistDetail = '/artist-detail';
  static const String artworkMeaning = '/artwork-meaning';
  static const String heritageStory = '/heritage-story';
  static const String foodOriginState = '/food-origin-state';
  static const String heritageVideo = '/heritage-video';

  // ── Module C ─────────────────────────────────────────────────────────────────
  static const String community = '/community';
  static const String communitySearch = '/community-search';
  static const String postDetail = '/post-detail';
  static const String createPost = '/create-post';
  static const String artworkCampaign = '/artwork-campaign';
  static const String campaignDetail =
      '/campaign-detail'; // → ArtworkCategoryListView
  static const String artworkVotingDetail = '/artwork-voting-detail';
  static const String artworkSubmission = '/artwork-submission';
  static const String artworkSubmissionSuccess = '/artwork-submission-success';
  static const String campaignRankings = '/campaign-rankings';

  // ── Module D ─────────────────────────────────────────────────────────────────
  static const String guestAccount = '/guest-account';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String resetPassword = '/reset-password';
  static const String emailVerification = '/email-verification';

  /// Route generator — maps named routes to their view widgets.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Module A
      case treasureMap:
        return _build(const TreasureMapView(), settings);
      case vendorSearch:
        return _build(
          VendorSearchResultView(query: settings.arguments as String? ?? ''),
          settings,
        );
      case vendorDetail:
        return _build(
          VendorDetailView(vendorId: settings.arguments as String? ?? ''),
          settings,
        );
      case routeNavigation:
        return _build(
          RouteNavigationView(vendorId: settings.arguments as String? ?? ''),
          settings,
        );

      // Module B
      case heritageExperience:
        return _build(const HeritageExperienceHomeView(), settings);
      case qrScanner:
        return _build(const QrScannerView(), settings);
      case scanResult:
        return _build(
          ScanResultView(result: settings.arguments as QrScanResultModel),
          settings,
        );
      case tiffinExperience:
        return _build(
          TiffinExperienceView(tiffinId: settings.arguments as String? ?? ''),
          settings,
        );
      case artistDetail:
        return _build(
          ArtistDetailView(artistId: settings.arguments as String? ?? ''),
          settings,
        );
      case artworkMeaning:
        return _build(
          ArtworkMeaningView(artworkId: settings.arguments as String? ?? ''),
          settings,
        );
      case heritageStory:
        return _build(
          HeritageStoryView(tiffinId: settings.arguments as String? ?? ''),
          settings,
        );
      case foodOriginState:
        return _build(
          FoodOriginStateView(foodId: settings.arguments as String? ?? ''),
          settings,
        );
      case heritageVideo:
        return _build(
          HeritageVideoView(mediaId: settings.arguments as String? ?? ''),
          settings,
        );

      // Module C
      case community:
        return _build(const CommunityHomeView(), settings);
      case communitySearch:
        return _build(
          CommunitySearchView(
            initialQuery: settings.arguments as String? ?? '',
          ),
          settings,
        );
      case postDetail:
        return _build(
          PostDetailView(postId: settings.arguments as String? ?? ''),
          settings,
        );
      case createPost:
        return _build(const CreatePostView(), settings);
      case artworkCampaign:
        return _build(const ArtworkCampaignHomeView(), settings);
      case campaignDetail:
        return _build(
          ArtworkCategoryListView(
            campaignId: settings.arguments as String? ?? '',
          ),
          settings,
        );
      case artworkVotingDetail:
        return _build(
          ArtworkVotingDetailView(entryId: settings.arguments as String? ?? ''),
          settings,
        );
      case artworkSubmission:
        final args = settings.arguments as Map<String, String>? ?? {};
        return _build(
          ArtworkSubmissionView(
            campaignId: args['campaignId'] ?? '',
            categoryId: args['categoryId'] ?? '',
          ),
          settings,
        );
      case artworkSubmissionSuccess:
        return _build(const ArtworkSubmissionSuccessView(), settings);
      case campaignRankings:
        return _build(
          CampaignRankingsView(campaignId: settings.arguments as String? ?? ''),
          settings,
        );

      // Module D
      case guestAccount:
        return _build(const GuestAccountView(), settings);
      case login:
        return _build(const LoginView(), settings);
      case register:
        return _build(const RegisterView(), settings);
      case forgotPassword:
        return _build(const ForgotPasswordView(), settings);
      case profile:
        return _build(const ProfileView(), settings);
      case editProfile:
        return _build(const EditProfileView(), settings);
      case changePassword:
        return _build(const ChangePasswordView(), settings);
      case resetPassword:
        return _build(const ResetPasswordView(), settings);
      case emailVerification:
        return _build(
          EmailVerificationView(email: settings.arguments as String? ?? ''),
          settings,
        );

      default:
        return _build(const TreasureMapView(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _build(Widget page, RouteSettings settings) {
    final bottomTab = settings.arguments is BottomTabTransition
        ? settings.arguments as BottomTabTransition
        : null;
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        if (bottomTab != null) {
          final x = switch (bottomTab.tabIndex) {
            0 => -0.67,
            1 => 0.0,
            _ => 0.67,
          };
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.06, end: 1).animate(curved),
              alignment: Alignment(x, 1),
              child: child,
            ),
          );
        }
        final slide = Tween<Offset>(
          begin: const Offset(0.045, 0),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

class BottomTabTransition {
  final int tabIndex;

  const BottomTabTransition(this.tabIndex);
}
