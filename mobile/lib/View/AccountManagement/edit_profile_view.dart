import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/AccountManagement/profile_view_model.dart';
import '../Widgets/error_state_widget.dart';

/// D6. Edit Profile View.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final ProfileViewModel _vm;
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthViewModel>();
      await _reloadProfile(auth);
    });
  }

  Future<void> _reloadProfile(
    AuthViewModel auth, {
    bool showLoading = true,
  }) async {
    if (auth.currentUser == null) return;
    await _vm.loadProfile(auth.currentUser!.id, showLoading: showLoading);
    if (_vm.profile != null) {
      _nameCtrl.text = _vm.profile!.displayName;
      _countryCtrl.text = _vm.profile!.country ?? '';
      _cityCtrl.text = _vm.profile!.city ?? '';
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ProfileViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (vm.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text(vm.successMessage!)));
              Navigator.pop(ctx);
            });
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: vm.isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            await _vm.saveProfile(
                              displayName: _nameCtrl.text.trim(),
                              country: _countryCtrl.text.trim().isEmpty
                                  ? null
                                  : _countryCtrl.text.trim(),
                              city: _cityCtrl.text.trim().isEmpty
                                  ? null
                                  : _cityCtrl.text.trim(),
                              avatar: vm.pendingAvatar,
                            );
                          },
                    child: vm.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
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
            body: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : vm.errorMessage != null && vm.profile == null
                ? ErrorStateWidget(
                    message: vm.errorMessage!,
                    onRetry: auth.currentUser == null
                        ? null
                        : () => _reloadProfile(auth),
                  )
                : RefreshIndicator(
                    onRefresh: () => _reloadProfile(auth, showLoading: false),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  final file = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 88,
                                  );
                                  if (file != null) vm.setPendingAvatar(file);
                                },
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: AppColors.accent,
                                      backgroundImage:
                                          vm.pendingAvatar == null &&
                                              vm.profile?.avatarUrl != null
                                          ? NetworkImage(vm.profile!.avatarUrl!)
                                          : null,
                                      child: vm.pendingAvatar != null
                                          ? ClipOval(
                                              child: FutureBuilder(
                                                future: vm.pendingAvatar!
                                                    .readAsBytes(),
                                                builder: (_, snapshot) =>
                                                    snapshot.hasData
                                                    ? Image.memory(
                                                        snapshot.data!,
                                                        width: 88,
                                                        height: 88,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const CircularProgressIndicator(),
                                              ),
                                            )
                                          : vm.profile?.avatarUrl == null
                                          ? Text(
                                              _nameCtrl.text.isNotEmpty
                                                  ? _nameCtrl.text[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 32,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Tap to change photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            _label('Display Name *'),
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Your display name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Display name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _label('Email'),
                            TextFormField(
                              initialValue: auth.currentUser?.email,
                              enabled: false,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _label('Country Code'),
                            TextFormField(
                              controller: _countryCtrl,
                              maxLength: 2,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'e.g. MY',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              validator: (value) =>
                                  value != null &&
                                      value.isNotEmpty &&
                                      value.trim().length != 2
                                  ? 'Use a two-letter country code'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            _label('City'),
                            TextFormField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Kuala Lumpur',
                                prefixIcon: Icon(Icons.location_city_rounded),
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
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
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
