import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageCommunity/artwork_submission_view_model.dart';
import 'artwork_image_capture_crop_view.dart';

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
              backgroundColor: Colors.white,
              appBar: const _ArtworkSubmissionHeader(),
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepBanner(
            step: '1',
            title: 'Artwork details',
            subtitle:
                'Tell reviewers about the idea, culture and meaning behind your work.',
            completed: vm.completedWrittenCount,
            total: 6,
          ),
          const SizedBox(height: 22),
          const Text(
            'About your artwork',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Keep your explanations clear and concise.',
            style: TextStyle(color: Color(0xFF7D887F), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _SimpleField(
            label: 'Artwork title',
            hint: 'e.g. Warisan Rempah',
            minLines: 1,
            maxLines: 1,
            maxLength: 180,
            onChanged: vm.setArtworkTitle,
          ),
          const SizedBox(height: 14),
          _SimpleField(
            label: 'Design description',
            hint: 'Describe colours, materials, patterns and visual elements…',
            onChanged: vm.setDesignDescription,
          ),
          const SizedBox(height: 14),
          _SimpleField(
            label: 'Cultural inspiration',
            hint:
                'Tell us about the heritage, place, craft or story behind it…',
            onChanged: vm.setCulturalInspiration,
          ),
          const SizedBox(height: 16),
          _LayerMeaningCard(
            onLayer1Changed: vm.setLayer1Meaning,
            onLayer2Changed: vm.setLayer2Meaning,
            onLayer3Changed: vm.setLayer3Meaning,
          ),
          const SizedBox(height: 16),
          _StepBanner(
            step: '2',
            title: 'Artwork photos',
            subtitle:
                'Add four clear, evenly lit views. The hero photo becomes the main voting image.',
            completed: vm.completedPhotoCount,
            total: 4,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.14,
            children: [
              _photoCard(
                vm,
                ArtworkPhotoView.frontHero,
                badge: 'Hero',
                title: 'Front',
                description: 'Main voting image',
                guidanceUrl: _frontGuidanceUrl,
              ),
              _photoCard(
                vm,
                ArtworkPhotoView.layer1Flat360,
                badge: '1',
                title: 'Layer 1',
                description: 'Front + back in one 5:1 image',
                guidanceUrl: _layerGuidanceUrl,
              ),
              _photoCard(
                vm,
                ArtworkPhotoView.layer2Flat360,
                badge: '2',
                title: 'Layer 2',
                description: 'Front + back in one 5:1 image',
                guidanceUrl: _layerGuidanceUrl,
              ),
              _photoCard(
                vm,
                ArtworkPhotoView.layer3Flat360,
                badge: '3',
                title: 'Layer 3',
                description: 'Front + back in one 5:1 image',
                guidanceUrl: _layerGuidanceUrl,
              ),
            ],
          ),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: vm.errorMessage!),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed:
                vm.canSubmit && !vm.isSubmitting && auth.currentUser != null
                ? () => vm.submit(
                    campaignId: widget.campaignId,
                    userId: auth.currentUser!.id,
                  )
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              elevation: 0,
              backgroundColor: const Color(0xFF24663F),
              disabledBackgroundColor: const Color(0xFFB7BDB8),
              disabledForegroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: vm.isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit for review'),
          ),
        ],
      ),
    );
  }

  Widget _photoCard(
    ArtworkSubmissionViewModel vm,
    ArtworkPhotoView view, {
    required String badge,
    required String title,
    required String description,
    required String guidanceUrl,
  }) {
    return _PhotoViewCard(
      badge: badge,
      title: title,
      description: description,
      file: vm.photoFor(view),
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
}

class _ArtworkSubmissionHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _ArtworkSubmissionHeader();

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderWaveClipper(),
      child: Material(
        color: const Color(0xFFF0F5EA),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, size: 23),
                  color: const Color(0xFF1D643C),
                ),
                const SizedBox(width: 8),
                Text(
                  'Submit Artwork',
                  style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                    fontSize: 22,
                    color: const Color(0xFF175C35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 9)
      ..cubicTo(
        size.width * .16,
        size.height + 9,
        size.width * .34,
        size.height + 4,
        size.width * .45,
        size.height - 24,
      )
      ..cubicTo(
        size.width * .56,
        size.height - 2,
        size.width * .72,
        size.height + 10,
        size.width,
        size.height - 5,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _StepBanner extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final int completed;
  final int total;

  const _StepBanner({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF24663F),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC127),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Color(0xFF183D29),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFE1ECE4),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Step $step of 2',
                style: const TextStyle(color: Color(0xFFE1ECE4), fontSize: 10),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF5B896C),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC127),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 88,
                child: Text(
                  '$completed of $total complete',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleField extends StatelessWidget {
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String> onChanged;

  const _SimpleField({
    required this.label,
    required this.hint,
    this.minLines = 2,
    this.maxLines = 4,
    this.maxLength,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequiredLabel(label),
        const SizedBox(height: 7),
        TextField(
          onChanged: onChanged,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14),
          decoration: _fieldDecoration(hint, outlined: true),
        ),
      ],
    );
  }
}

class _LayerMeaningCard extends StatelessWidget {
  final ValueChanged<String> onLayer1Changed;
  final ValueChanged<String> onLayer2Changed;
  final ValueChanged<String> onLayer3Changed;

  const _LayerMeaningCard({
    required this.onLayer1Changed,
    required this.onLayer2Changed,
    required this.onLayer3Changed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What your layers mean',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Explain the symbolism behind each layer.',
          style: TextStyle(color: Color(0xFF7D887F), fontSize: 12),
        ),
        const SizedBox(height: 10),
        _LayerField(number: '1', label: 'Layer 1', onChanged: onLayer1Changed),
        const SizedBox(height: 10),
        _LayerField(number: '2', label: 'Layer 2', onChanged: onLayer2Changed),
        const SizedBox(height: 10),
        _LayerField(
          number: '3',
          label: 'Layer 3',
          goldBadge: true,
          onChanged: onLayer3Changed,
        ),
      ],
    );
  }
}

class _LayerField extends StatelessWidget {
  final String number;
  final String label;
  final bool goldBadge;
  final ValueChanged<String> onChanged;

  const _LayerField({
    required this.number,
    required this.label,
    this.goldBadge = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDDAC7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: goldBadge
                  ? const Color(0xFFFFF1C8)
                  : const Color(0xFFEAF2E7),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF52715A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: TextField(
                    onChanged: onChanged,
                    minLines: 1,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 12),
                    decoration: _fieldDecoration(
                      'Describe its meaning…',
                      compact: true,
                      outlined: true,
                    ),
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

class _RequiredLabel extends StatelessWidget {
  final String label;

  const _RequiredLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: const [
          TextSpan(
            text: '  *',
            style: TextStyle(color: AppColors.error),
          ),
        ],
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  String hint, {
  bool outlined = false,
  bool compact = false,
}) {
  return InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: const Color(0xFFF5F7F3),
    hintStyle: const TextStyle(color: Color(0xFF929B94), fontSize: 12),
    contentPadding: compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 10 : 13),
      borderSide: outlined
          ? const BorderSide(color: Color(0xFFCDDAC7))
          : BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 10 : 13),
      borderSide: outlined
          ? const BorderSide(color: Color(0xFFCDDAC7))
          : BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(compact ? 10 : 13),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

class _PhotoViewCard extends StatelessWidget {
  final String badge;
  final String title;
  final String description;
  final XFile? file;
  final VoidCallback onGuidance;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PhotoViewCard({
    required this.badge,
    required this.title,
    required this.description,
    required this.file,
    required this.onGuidance,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = file != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCDDAC7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Material(
              color: const Color(0xFFF6F8F3),
              child: InkWell(
                onTap: onAdd,
                child: selected
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _XFilePreview(file: file!),
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton.filledTonal(
                              tooltip: 'Remove $title',
                              visualDensity: VisualDensity.compact,
                              onPressed: onRemove,
                              icon: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 27,
                            color: Color(0xFF17603A),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Add photo',
                            style: TextStyle(
                              color: Color(0xFF17603A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: badge == 'Hero'
                            ? const Color(0xFFFFE9A9)
                            : const Color(0xFFEAF2E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF344E3C),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkResponse(
                      onTap: onGuidance,
                      radius: 18,
                      child: const Icon(
                        Icons.info_outline,
                        size: 17,
                        color: Color(0xFF17603A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF748179),
                    fontSize: 11,
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
