import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/AccountManagement/my_reviews_view_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/post_card.dart';

/// Reviews authored by the signed-in account.
class MyReviewsView extends StatefulWidget {
  const MyReviewsView({super.key});

  @override
  State<MyReviewsView> createState() => _MyReviewsViewState();
}

class _MyReviewsViewState extends State<MyReviewsView> {
  late final MyReviewsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = MyReviewsViewModel();
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
      child: Consumer2<MyReviewsViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('My Reviews')),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.errorMessage != null
              ? ErrorStateWidget(
                  message: vm.errorMessage!,
                  onRetry: () => vm.load(auth.currentUser!.id),
                )
              : vm.reviews.isEmpty
              ? RefreshableStateView(
                  onRefresh: () => vm.load(
                    auth.currentUser!.id,
                    showLoading: false,
                  ),
                  child: const EmptyStateWidget(
                    icon: Icons.rate_review_outlined,
                    title: 'No reviews yet',
                    subtitle: 'Share a heritage food experience to see it here.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => vm.load(
                    auth.currentUser!.id,
                    showLoading: false,
                  ),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: vm.reviews.length,
                    itemBuilder: (_, index) {
                      final review = vm.reviews[index];
                      return PostCard(
                        post: review,
                        isLoggedIn: true,
                        onTap: () => Navigator.pushNamed(
                          ctx,
                          AppRoutes.postDetail,
                          arguments: review.id,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
