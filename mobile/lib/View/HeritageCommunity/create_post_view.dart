import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/HeritageCommunity/create_post_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../HeritageTreasureMap/treasure_map_view.dart';
import '../Widgets/rating_bar.dart';
import 'heritage_community_style.dart';

/// C4. Create Community Post Form.
class CreatePostView extends StatefulWidget {
  final String? initialVendorId;
  final String? initialVendorName;

  const CreatePostView({
    super.key,
    this.initialVendorId,
    this.initialVendorName,
  });

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  late final CreatePostViewModel _vm;
  final ImagePicker _picker = ImagePicker();
  final _reviewCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _vm = CreatePostViewModel();
    if (widget.initialVendorId != null) {
      _vm.selectVendor(
        widget.initialVendorId!,
        widget.initialVendorName ?? 'Selected vendor',
      );
    }
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
            backgroundColor: HeritageCommunityStyle.background,
            appBar: heritageCommunityAppBar(title: 'Share a Story'),
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
                            onTap: widget.initialVendorId == null
                                ? () => _selectVendorFromMap(ctx, vm)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.divider),
                                boxShadow: HeritageCommunityStyle.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.map_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      vm.selectedVendorName ??
                                          'Choose a vendor from the heritage map',
                                      style: TextStyle(
                                        color: vm.selectedVendorName != null
                                            ? AppColors.textPrimary
                                            : AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    widget.initialVendorId == null
                                        ? Icons.chevron_right_rounded
                                        : Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                ],
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
                                  onTap: () => _choosePhotoSource(ctx, vm),
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
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed:
                                !vm.isSubmitting && auth.currentUser != null
                                ? () => _publishPost(ctx, vm, auth)
                                : null,
                            icon: vm.isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.publish_rounded),
                            label: Text(
                              vm.isSubmitting ? 'Publishing…' : 'Publish Post',
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _publishPost(
    BuildContext context,
    CreatePostViewModel vm,
    AuthViewModel auth,
  ) async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final ok = await vm.submitPost(auth.currentUser!.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published successfully!')),
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.postDetail,
        arguments: vm.createdPost!.id,
      );
    } else if (!formValid || vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? 'Please correct the highlighted fields.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _choosePhotoSource(
    BuildContext context,
    CreatePostViewModel vm,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      requestFocus: false,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Add post photos',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Add up to 5 photos to your story.'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 82,
        );
        if (photo != null) vm.addPhotos([photo]);
      } else {
        final photos = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 82,
          limit: AppConstants.maxPostPhotos - vm.photos.length,
        );
        vm.addPhotos(photos);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photos could not be added: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _selectVendorFromMap(
    BuildContext context,
    CreatePostViewModel vm,
  ) async {
    final vendor = await Navigator.push<VendorModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const TreasureMapView(selectionMode: true),
        settings: const RouteSettings(name: 'vendor-map-selection'),
      ),
    );
    if (vendor != null) vm.selectVendor(vendor.id, vendor.name);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
