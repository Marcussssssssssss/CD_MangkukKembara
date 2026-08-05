import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/artwork_submission_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';

/// C8. Submit Artwork Form View.
class ArtworkSubmissionView extends StatefulWidget {
  final String campaignId;
  final String categoryId;
  const ArtworkSubmissionView({
    super.key,
    required this.campaignId,
    required this.categoryId,
  });

  @override
  State<ArtworkSubmissionView> createState() => _ArtworkSubmissionViewState();
}

class _ArtworkSubmissionViewState extends State<ArtworkSubmissionView> {
  late final ArtworkSubmissionViewModel _vm;

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
              Navigator.pushReplacementNamed(
                ctx,
                AppRoutes.artworkSubmissionSuccess,
              );
            });
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Submit Your Artwork'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed:
                        vm.canSubmit &&
                            !vm.isSubmitting &&
                            auth.currentUser != null
                        ? () => _vm.submit(
                            campaignId: widget.campaignId,
                            categoryId: widget.categoryId,
                            userId: auth.currentUser!.id,
                          )
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
                            'Submit',
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
                          const Text('Login required to submit artwork.'),
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Artwork Title *'),
                        _field('e.g. Warisan Rempah', vm.setArtworkTitle),
                        const SizedBox(height: 16),

                        _label('Design Description *'),
                        _area(
                          'Describe the visual elements of your artwork...',
                          vm.setDesignDescription,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 16),

                        _label('Cultural Inspiration *'),
                        _area(
                          'What Malaysian heritage elements inspired this artwork?',
                          vm.setCulturalInspiration,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        _label('Artist Statement *'),
                        _area(
                          'Why did you create this artwork and what does it mean to you?',
                          vm.setArtistStatement,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),

                        _label('Artwork File * (JPG, PNG, WebP)'),
                        GestureDetector(
                          onTap: vm.hasUploadedFile
                              ? vm.removeFile
                              : () async {
                                  final file = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 92,
                                  );
                                  if (file != null) _vm.setArtworkFile(file);
                                },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: vm.hasUploadedFile
                                  ? AppColors.successLight
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: vm.hasUploadedFile
                                    ? AppColors.success
                                    : AppColors.divider,
                                width: vm.hasUploadedFile ? 2 : 1,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  vm.hasUploadedFile
                                      ? Icons.check_circle_rounded
                                      : Icons.upload_file_rounded,
                                  size: 36,
                                  color: vm.hasUploadedFile
                                      ? AppColors.success
                                      : AppColors.textHint,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  vm.hasUploadedFile
                                      ? '${vm.artworkFile!.name} (tap to remove)'
                                      : 'Tap to upload artwork file',
                                  style: TextStyle(
                                    color: vm.hasUploadedFile
                                        ? AppColors.success
                                        : AppColors.textHint,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (vm.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              vm.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'All submissions are reviewed by the MangkukKembara team before appearing in the public voting list.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _field(String hint, Function(String) onChange) {
    return TextField(
      decoration: InputDecoration(hintText: hint),
      onChanged: onChange,
    );
  }

  Widget _area(String hint, Function(String) onChange, {int maxLines = 3}) {
    return TextField(
      decoration: InputDecoration(hintText: hint, alignLabelWithHint: true),
      maxLines: maxLines,
      onChanged: onChange,
    );
  }
}
