import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_submission_view_model.dart';
import 'artwork_image_capture_crop_view.dart';
import 'heritage_community_style.dart';

/// Guided artwork submission with the four views required for review.
class ArtworkSubmissionView extends StatefulWidget {
  final String campaignId;

  const ArtworkSubmissionView({super.key, required this.campaignId});

  @override
  State<ArtworkSubmissionView> createState() => _ArtworkSubmissionViewState();
}

class _ArtworkSubmissionViewState extends State<ArtworkSubmissionView> {
  static const _layerGuidanceUrl =
      'https://res.cloudinary.com/hv2ectij/image/upload/v1787577747/tiffin_5to1_guideline_fixed_ojjzyx.png';
  static const _frontGuidanceUrl =
      'https://res.cloudinary.com/hv2ectij/image/upload/v1787577747/tiffin_3_layer_front_view_guideline_pls4br.png';
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
                'Each layer image is one 30 cm × 6 cm canvas: FRONT on the left and BACK on the right.',
            child: Column(
              children: [
                _photoCard(
                  vm,
                  ArtworkPhotoView.frontHero,
                  title: '1. Front / Hero View',
                  description:
                      'Show the complete assembled tiffin straight on. This becomes the main voting image.',
                  icon: Icons.crop_portrait_rounded,
                  guidanceUrl: _frontGuidanceUrl,
                ),
                const SizedBox(height: 12),
                _photoCard(
                  vm,
                  ArtworkPhotoView.layer1Flat360,
                  title: '2. Layer 1 Design',
                  description:
                      'Upload one 5:1 image containing the 15 cm front and 15 cm back designs.',
                  icon: Icons.panorama_horizontal_rounded,
                  isTiffinLayer: true,
                  guidanceUrl: _layerGuidanceUrl,
                ),
                const SizedBox(height: 12),
                _photoCard(
                  vm,
                  ArtworkPhotoView.layer2Flat360,
                  title: '3. Layer 2 Design',
                  description:
                      'Upload one 5:1 image containing the 15 cm front and 15 cm back designs.',
                  icon: Icons.panorama_horizontal_rounded,
                  isTiffinLayer: true,
                  guidanceUrl: _layerGuidanceUrl,
                ),
                const SizedBox(height: 12),
                _photoCard(
                  vm,
                  ArtworkPhotoView.layer3Flat360,
                  title: '4. Layer 3 Design',
                  description:
                      'Upload one 5:1 image containing the 15 cm front and 15 cm back designs.',
                  icon: Icons.panorama_horizontal_rounded,
                  isTiffinLayer: true,
                  guidanceUrl: _layerGuidanceUrl,
                ),
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
    bool isTiffinLayer = false,
    required String guidanceUrl,
  }) {
    return _PhotoViewCard(
      title: title,
      description: description,
      icon: icon,
      file: vm.photoFor(view),
      isTiffinLayer: isTiffinLayer,
      onGuidance: () => _showGuidance(title, guidanceUrl),
      onAdd: () => _choosePhotoSource(view),
      onRemove: () => vm.removeArtworkPhoto(view),
    );
  }

  Future<void> _choosePhotoSource(ArtworkPhotoView view) async {
    _clearMediaFocus();
    final isLayer = ArtworkSubmissionViewModel.isLayerView(view);
    final viewTitle = switch (view) {
      ArtworkPhotoView.frontHero => 'Front View',
      ArtworkPhotoView.layer1Flat360 => 'Layer 1 Design',
      ArtworkPhotoView.layer2Flat360 => 'Layer 2 Design',
      ArtworkPhotoView.layer3Flat360 => 'Layer 3 Design',
    };
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      requestFocus: false,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Add artwork photo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                isLayer
                    ? 'The image will be cropped to a fixed 5:1 ratio.'
                    : 'The original image ratio will be preserved.',
              ),
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
    _clearMediaFocus();
    if (source == null || !mounted) return;

    if (!isLayer) {
      final sourceFile = await _picker.pickImage(
        source: source,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 95,
      );
      _clearMediaFocus();
      if (sourceFile == null || !mounted) return;

      try {
        final webpFile = await convertArtworkImageToWebP(sourceFile);
        final validationMessage = await _vm.setArtworkPhoto(view, webpFile);
        if (validationMessage != null && mounted) {
          _showMediaError(validationMessage);
        }
      } catch (_) {
        if (mounted) {
          _showMediaError(
            'This image format could not be converted to WebP. Choose another image.',
          );
        }
      } finally {
        _clearMediaFocusAfterReturn();
      }
      return;
    }

    XFile? sourceFile;
    if (source == ImageSource.camera) {
      _clearMediaFocus();
      sourceFile = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (_) => ArtworkCameraCaptureView(
            title: viewTitle,
            aspectRatio: ArtworkSubmissionViewModel.layerAspectRatio,
          ),
        ),
      );
    } else {
      sourceFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 95,
      );
    }
    _clearMediaFocus();
    if (sourceFile == null || !mounted) return;

    final croppedFile = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => ArtworkImageCropView(
          sourceFile: sourceFile!,
          title: viewTitle,
          aspectRatio: ArtworkSubmissionViewModel.layerAspectRatio,
        ),
      ),
    );
    _clearMediaFocus();
    if (croppedFile == null || !mounted) return;

    final validationMessage = await _vm.setArtworkPhoto(view, croppedFile);
    if (validationMessage != null && mounted) {
      _showMediaError(validationMessage);
    }
    _clearMediaFocusAfterReturn();
  }

  void _clearMediaFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) FocusScope.of(context).unfocus();
  }

  void _clearMediaFocusAfterReturn() {
    _clearMediaFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _clearMediaFocus();
    });
  }

  void _showMediaError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showGuidance(String title, String imageUrl) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$title guidance',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close guidance',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            height: 280,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 220,
                      child: Center(
                        child: Text('The guidance image could not be loaded.'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final bool isTiffinLayer;
  final VoidCallback onGuidance;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PhotoViewCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.file,
    this.isTiffinLayer = false,
    required this.onGuidance,
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
          if (selected && isTiffinLayer)
            AspectRatio(
              aspectRatio: ArtworkSubmissionViewModel.layerAspectRatio,
              child: _XFilePreview(file: file!),
            )
          else if (selected)
            _XFilePreview(file: file!),
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
                          IconButton(
                            tooltip: 'View guidance for $title',
                            visualDensity: VisualDensity.compact,
                            onPressed: onGuidance,
                            icon: const Icon(Icons.help_outline_rounded),
                            color: AppColors.primary,
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
                          file!.name.isEmpty
                              ? 'Converted WebP image'
                              : file!.name,
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

class _XFilePreview extends StatefulWidget {
  final XFile file;

  const _XFilePreview({required this.file});

  @override
  State<_XFilePreview> createState() => _XFilePreviewState();
}

class _XFilePreviewState extends State<_XFilePreview> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _XFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file != widget.file) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, size: 36),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
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
