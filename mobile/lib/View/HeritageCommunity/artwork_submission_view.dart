import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_submission_view_model.dart';
import 'heritage_community_style.dart';

/// Guided artwork submission with the four views required for review.
class ArtworkSubmissionView extends StatefulWidget {
  final String campaignId;

  const ArtworkSubmissionView({super.key, required this.campaignId});

  @override
  State<ArtworkSubmissionView> createState() => _ArtworkSubmissionViewState();
}

class _ArtworkSubmissionViewState extends State<ArtworkSubmissionView> {
  late final ArtworkSubmissionViewModel _vm;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _vm = ArtworkSubmissionViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkSubmissionViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (vm.success) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!ctx.mounted) return;
              Navigator.pushReplacementNamed(
                ctx,
                AppRoutes.artworkSubmissionSuccess,
              );
            });
          }
          return PopScope(
            canPop: !vm.isSubmitting,
            child: Scaffold(
              backgroundColor: HeritageCommunityStyle.background,
              appBar: heritageCommunityAppBar(title: 'Submit Artwork'),
              body: !auth.isLoggedIn
                  ? _LoginRequired(
                      onLogin: () => Navigator.pushNamed(ctx, AppRoutes.login),
                    )
                  : _buildForm(ctx, vm, auth),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ArtworkSubmissionViewModel vm,
    AuthViewModel auth,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            step: '1',
            title: 'Tell us about your artwork',
            subtitle: 'These details help reviewers understand your work.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Artwork title'),
                _field(
                  hint: 'Example: Warisan Rempah',
                  onChanged: vm.setArtworkTitle,
                  maxLength: 180,
                ),
                const SizedBox(height: 14),
                _label('Design description'),
                _area(
                  hint:
                      'Describe the colours, materials, patterns and visual elements.',
                  onChanged: vm.setDesignDescription,
                ),
                const SizedBox(height: 14),
                _label('Cultural inspiration'),
                _area(
                  hint:
                      'Which Malaysian heritage, place, craft or story inspired it?',
                  onChanged: vm.setCulturalInspiration,
                ),
                const SizedBox(height: 14),
                _label('Layer 1 meaning'),
                _area(
                  hint:
                      'What does the artwork on Layer 1 represent, and why is it meaningful?',
                  onChanged: vm.setLayer1Meaning,
                ),
                const SizedBox(height: 14),
                _label('Layer 2 meaning'),
                _area(
                  hint:
                      'Explain the story, heritage elements or symbolism shown on Layer 2.',
                  onChanged: vm.setLayer2Meaning,
                ),
                const SizedBox(height: 14),
                _label('Layer 3 meaning'),
                _area(
                  hint:
                      'Explain the meaning and cultural significance of the Layer 3 artwork.',
                  onChanged: vm.setLayer3Meaning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            step: '2',
            title: 'Add four required artwork views',
            subtitle:
                'Follow the required tiffin layout. Each flattened layer must show continuous artwork from seam to seam.',
            child: Column(
              children: [
                _photoCard(
                  vm,
                  ArtworkPhotoView.frontHero,
                  title: '1. Front / Hero View',
                  description:
                      'Show the complete assembled tiffin straight on. This becomes the main voting image.',
                  icon: Icons.crop_portrait_rounded,
                ),
                const SizedBox(height: 12),
                _photoCard(
                  vm,
                  ArtworkPhotoView.layer1Flat360,
                  title: '2. Layer 1 Flat 360°',
                  description:
                      'Upload the full flattened circumference artwork for layer 1, including side and back areas.',
                  icon: Icons.panorama_horizontal_rounded,
                  previewAspectRatio: 3,
                ),
                const SizedBox(height: 12),
                _photoCard(
                  vm,
                  ArtworkPhotoView.layer2Flat360,
                  title: '3. Layer 2 Flat 360°',
                  description:
                      'Upload the full flattened circumference artwork for layer 2, from seam/start to end/seam.',
                  icon: Icons.panorama_horizontal_rounded,
                  previewAspectRatio: 3,
                ),
                const SizedBox(height: 12),
                _photoCard(
                  vm,
                  ArtworkPhotoView.layer3Flat360,
                  title: '4. Layer 3 Flat 360°',
                  description:
                      'Upload the full flattened circumference artwork for layer 3, including every visible side.',
                  icon: Icons.panorama_horizontal_rounded,
                  previewAspectRatio: 3,
                ),
                const SizedBox(height: 12),
                const _UploadRequirements(),
              ],
            ),
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: vm.errorMessage!),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed:
                vm.canSubmit && !vm.isSubmitting && auth.currentUser != null
                ? () => vm.submit(
                    campaignId: widget.campaignId,
                    userId: auth.currentUser!.id,
                  )
                : null,
            icon: vm.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              vm.isSubmitting ? 'Uploading 4 views…' : 'Submit for review',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            vm.canSubmit
                ? 'Ready to submit. Your entry will be locked while it is under review.'
                : 'Complete all written fields and add all 4 required views.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCard(
    ArtworkSubmissionViewModel vm,
    ArtworkPhotoView view, {
    required String title,
    required String description,
    required IconData icon,
    double previewAspectRatio = 16 / 9,
  }) {
    return _PhotoViewCard(
      title: title,
      description: description,
      icon: icon,
      file: vm.photoFor(view),
      previewAspectRatio: previewAspectRatio,
      onAdd: () => _choosePhotoSource(view),
      onRemove: () => vm.removeArtworkPhoto(view),
    );
  }

  Future<void> _choosePhotoSource(ArtworkPhotoView view) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Add artwork photo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Choose a clear, high-resolution image.'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      maxWidth: 3000,
      maxHeight: 3000,
      imageQuality: 90,
    );
    if (file != null) _vm.setArtworkPhoto(view, file);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const Text('  *', style: TextStyle(color: AppColors.error)),
      ],
    ),
  );

  Widget _field({
    required String hint,
    required ValueChanged<String> onChanged,
    int? maxLength,
  }) => TextField(
    decoration: InputDecoration(hintText: hint, counterText: ''),
    textCapitalization: TextCapitalization.sentences,
    maxLength: maxLength,
    onChanged: onChanged,
  );

  Widget _area({
    required String hint,
    required ValueChanged<String> onChanged,
  }) => TextField(
    decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
    minLines: 3,
    maxLines: 5,
    textCapitalization: TextCapitalization.sentences,
    onChanged: onChanged,
  );
}

class _SectionCard extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: HeritageCommunityStyle.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentLight, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: const TextStyle(
                    color: AppColors.textOnAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PhotoViewCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final XFile? file;
  final double previewAspectRatio;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PhotoViewCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.file,
    this.previewAspectRatio = 16 / 9,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = file != null;
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.successLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.success : AppColors.divider,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected)
            AspectRatio(
              aspectRatio: previewAspectRatio,
              child: Image.file(
                File(file!.path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 36),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : icon,
                  color: selected ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            selected ? 'Added' : 'Required',
                            style: TextStyle(
                              color: selected
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 5),
                        Text(
                          file!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: Icon(
                      selected
                          ? Icons.change_circle_outlined
                          : Icons.add_a_photo_outlined,
                    ),
                    label: Text(selected ? 'Replace' : 'Add photo'),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remove $title',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadRequirements extends StatelessWidget {
  const _UploadRequirements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'JPG, PNG or WebP · maximum 10 MB per photo · avoid filters, glare and cropped edges.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginRequired({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
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
            const Text('Log in to submit your artwork.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onLogin,
              child: const Text('Login / Register'),
            ),
          ],
        ),
      ),
    );
  }
}
