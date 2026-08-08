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
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ArtworkSubmissionDetailPage(submission: submission),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                submission.artworkTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              _StatusPill(status: submission.reviewStatus),
              const SizedBox(height: 6),
              Text(
                submission.campaignName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.2,
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
                        fontSize: 12,
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
    ),
  );
}

class _ArtworkSubmissionDetailPage extends StatelessWidget {
  const _ArtworkSubmissionDetailPage({required this.submission});

  final ArtworkSubmissionModel submission;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      toolbarHeight: 64,
      title: const Text(
        'Artwork Submission',
        style: TextStyle(fontSize: 24),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryContainer, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 13,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SizedBox(
            height: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: ColoredBox(
                color: AppColors.surface,
                child: submission.artworkFileUrl == null
                    ? const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textHint,
                        size: 48,
                      )
                    : Image.network(
                        submission.artworkFileUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint,
                          size: 48,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                submission.artworkTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _StatusPill(status: submission.reviewStatus, isCompact: false),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primaryContainer, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _SubmissionDetailRow(
                icon: Icons.palette_outlined,
                label: 'Campaign',
                value: submission.campaignName,
              ),
              const Divider(indent: 66),
              _SubmissionDetailRow(
                icon: Icons.account_balance_outlined,
                label: 'Category',
                value: submission.categoryName,
              ),
              const Divider(indent: 66),
              _SubmissionDetailRow(
                icon: Icons.calendar_month_outlined,
                label: 'Submitted',
                value: DateFormat('d MMMM yyyy').format(submission.submittedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Design Description',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryContainer, width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            submission.designDescription?.trim().isNotEmpty == true
                ? submission.designDescription!
                : 'No design description was provided.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SubmissionDetailRow extends StatelessWidget {
  const _SubmissionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 16, left: 8),
          child: Icon(icon, color: AppColors.primary, size: 25),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    width: 96,
    height: 130,
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
  const _StatusPill({required this.status, this.isCompact = true});

  final String? status;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      'approved' => ('Approved', AppColors.success, AppColors.successLight),
      'rejected' => ('Rejected', AppColors.error, AppColors.errorLight),
      _ => ('Pending', AppColors.warning, AppColors.warningLight),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 9 : 14,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: isCompact ? 11 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
