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
                          const _CreatePostIntro(),
                          const SizedBox(height: 20),
                          // Vendor selector
                          _SectionLabel('Vendor *'),
                          GestureDetector(
                            onTap: () => _selectVendorFromMap(ctx, vm),
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
                                  const Icon(
                                    Icons.chevron_right_rounded,
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

  Future<void> _selectVendorFromMap(
    BuildContext context,
    CreatePostViewModel vm,
  ) async {
    final vendor = await Navigator.push<VendorModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const TreasureMapView(),
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

class _CreatePostIntro extends StatelessWidget {
  const _CreatePostIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF416F43), Color(0xFF203F2A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: HeritageCommunityStyle.cardShadow,
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Color(0x22FFFFFF),
            child: Icon(Icons.edit_note_rounded, color: Colors.white, size: 27),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR HERITAGE MOMENT',
                  style: TextStyle(
                    color: AppColors.accentLight,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Turn a meal into a story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Choose a place, add your rating, and share what made it memorable.',
                  style: TextStyle(
                    color: Color(0xDFFFFFFF),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
