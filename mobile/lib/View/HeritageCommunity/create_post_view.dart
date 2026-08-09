import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/HeritageCommunity/create_post_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../Widgets/rating_bar.dart';

/// C4. Create Community Post Form.
class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  late final CreatePostViewModel _vm;
  final _reviewCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _vm = CreatePostViewModel();
    _vm.loadVendors();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<CreatePostViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Share Heritage Experience'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: !vm.isSubmitting && auth.currentUser != null
                        ? () async {
                            final formValid =
                                _formKey.currentState?.validate() ?? false;
                            final ok = await _vm.submitPost(
                              auth.currentUser!.id,
                            );
                            if (ok && ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Post published successfully!'),
                                ),
                              );
                              Navigator.pushReplacementNamed(
                                ctx,
                                AppRoutes.postDetail,
                                arguments: vm.createdPost!.id,
                              );
                            } else if (ctx.mounted &&
                                (!formValid || vm.errorMessage != null)) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    vm.errorMessage ??
                                        'Please correct the highlighted fields.',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        : null,
                    child: vm.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Publish',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            body: !auth.isLoggedIn
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text('Login required to publish a post.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(ctx, AppRoutes.login),
                            child: const Text('Login / Register'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vendor selector
                          _SectionLabel('Vendor *'),
                          GestureDetector(
                            onTap: () async {
                              await _showVendorPicker(ctx, vm);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: vm.selectedVendorId == null
                                      ? AppColors.error.withAlpha(100)
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_rounded,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      vm.selectedVendorName ??
                                          'Select a vendor... (tap to choose)',
                                      style: TextStyle(
                                        color: vm.selectedVendorName != null
                                            ? AppColors.textPrimary
                                            : AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: AppColors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (vm.selectedVendorId == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 4, left: 4),
                              child: Text(
                                'Please select a vendor',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Star rating
                          _SectionLabel('Your Rating *'),
                          Row(
                            children: [
                              RatingSelector(
                                rating: vm.rating,
                                onChanged: _vm.setRating,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                vm.rating == 0
                                    ? 'Tap to rate'
                                    : vm.rating == 5
                                    ? 'Outstanding!'
                                    : vm.rating >= 4
                                    ? 'Very Good'
                                    : vm.rating >= 3
                                    ? 'Good'
                                    : vm.rating >= 2
                                    ? 'Fair'
                                    : 'Poor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Review text
                          _SectionLabel('Review *'),
                          TextFormField(
                            controller: _reviewCtrl,
                            maxLength: AppConstants.maxReviewLength,
                            maxLines: 5,
                            minLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Share your heritage food experience here...',
                              alignLabelWithHint: true,
                            ),
                            onChanged: _vm.setReviewText,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Review text is required';
                              }
                              if (v.trim().length <
                                  AppConstants.minReviewLength) {
                                return 'Review must be at least ${AppConstants.minReviewLength} characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Photos
                          _SectionLabel('Photos (optional, max 5)'),
                          Row(
                            children: [
                              ...vm.photos.asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: FutureBuilder(
                                          future: e.value.readAsBytes(),
                                          builder: (_, snapshot) => SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: snapshot.hasData
                                                ? Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const ColoredBox(
                                                    color: AppColors
                                                        .surfaceVariant,
                                                    child: Icon(
                                                      Icons.image_rounded,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: GestureDetector(
                                          onTap: () => _vm.removePhoto(e.key),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (vm.photos.length < AppConstants.maxPostPhotos)
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      final files = await ImagePicker()
                                          .pickMultiImage(
                                            maxWidth: 1920,
                                            maxHeight: 1920,
                                            imageQuality: 82,
                                            limit:
                                                AppConstants.maxPostPhotos -
                                                vm.photos.length,
                                          );
                                      _vm.addPhotos(files);
                                    } catch (error) {
                                      if (!ctx.mounted) return;
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Photos could not be selected: $error',
                                          ),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.divider,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Error message
                          if (vm.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      vm.errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _showVendorPicker(
    BuildContext context,
    CreatePostViewModel vm,
  ) async {
    if (vm.isLoadingVendors) return;
    if (vm.vendors.isEmpty) {
      await vm.loadVendors();
      if (!context.mounted || vm.vendors.isEmpty) return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          itemCount: vm.vendors.length,
          itemBuilder: (_, index) {
            final vendor = vm.vendors[index];
            return ListTile(
              leading: const Icon(Icons.storefront_rounded),
              title: Text(vendor.name),
              subtitle: Text(
                vendor.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                vm.selectVendor(vendor.id, vendor.name);
                Navigator.pop(sheetContext);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
