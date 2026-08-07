import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageCommunity/artwork_submission_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/AccountManagement/my_artwork_submissions_view_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

/// Artwork entries submitted by the signed-in account, with their review state.
class MyArtworkSubmissionsView extends StatefulWidget {
  const MyArtworkSubmissionsView({super.key});

  @override
  State<MyArtworkSubmissionsView> createState() =>
      _MyArtworkSubmissionsViewState();
}

class _MyArtworkSubmissionsViewState extends State<MyArtworkSubmissionsView> {
  late final MyArtworkSubmissionsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = MyArtworkSubmissionsViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthViewModel>();
      if (auth.isLoggedIn && auth.currentUser != null) {
        _vm.load(auth.currentUser!.id);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<MyArtworkSubmissionsViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('My Artwork Submissions')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.errorMessage != null
              ? ErrorStateWidget(
                  message: vm.errorMessage!,
                  onRetry: () => vm.load(auth.currentUser!.id),
                )
              : vm.submissions.isEmpty
              ? RefreshableStateView(
                  onRefresh: () => vm.load(
                    auth.currentUser!.id,
                    showLoading: false,
                  ),
                  child: const EmptyStateWidget(
                    icon: Icons.brush_outlined,
                    title: 'No artwork submissions yet',
                    subtitle: 'Submit an artwork to a campaign to track it here.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => vm.load(
                    auth.currentUser!.id,
                    showLoading: false,
                  ),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.submissions.length,
                    itemBuilder: (_, index) => _SubmissionCard(
                      submission: vm.submissions[index],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission});

  final ArtworkSubmissionModel submission;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppColors.divider.withAlpha(170)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ArtworkPreview(url: submission.artworkFileUrl),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 140,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      submission.artworkTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(status: submission.reviewStatus),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                submission.campaignName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Submitted ${DateFormat('d MMM yyyy').format(submission.submittedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 30,
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArtworkPreview extends StatelessWidget {
  const _ArtworkPreview({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 116,
    height: 140,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: ColoredBox(
        color: const Color(0xFFFCF8F1),
        child: url == null
            ? const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textHint,
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                ),
              ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      'approved' => ('Approved', AppColors.success, AppColors.successLight),
      'rejected' => ('Rejected', AppColors.error, AppColors.errorLight),
      _ => ('Pending', AppColors.warning, AppColors.warningLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
