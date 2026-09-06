import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/AccountManagement/password_recovery_view_model.dart';
import '../../core/email_address_validator.dart';
import '../Widgets/auth_branding.dart';

/// D5. Forgot Password View.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final PasswordRecoveryViewModel _vm;
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _vm = PasswordRecoveryViewModel();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<PasswordRecoveryViewModel>(
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(
              onPressed: () {
                final navigator = Navigator.of(ctx);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushReplacementNamed(AppRoutes.login);
                }
              },
            ),
          ),
          body: AuthPageLayout(
            child: Transform.translate(
              offset: const Offset(0, -64),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_open_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reset Your Password',
                      style: Theme.of(ctx).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Your registered email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: EmailAddressValidator.validate,
                    ),

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (vm.successMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.successMessage!,
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await _vm.sendResetEmail(
                                  _emailCtrl.text.trim(),
                                );
                              },
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password form shown after Supabase validates a recovery deep link.
class ResetPasswordView extends StatefulWidget {
  final bool recoverySessionVerified;
  final bool wasAuthenticated;

  const ResetPasswordView({
    super.key,
    this.recoverySessionVerified = false,
    this.wasAuthenticated = false,
  });

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  late final PasswordRecoveryViewModel _vm;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _vm = PasswordRecoveryViewModel();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _leaveRecovery() async {
    if (widget.wasAuthenticated) {
      await context.read<AuthViewModel>().finalizeAuthenticatedRecovery();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.profile,
        (route) => route.settings.name == AppRoutes.treasureMap,
      );
    } else {
      await _vm.endRecoverySession();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.forgotPassword,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<PasswordRecoveryViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(
              onPressed: _leaveRecovery,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 52),
                const Icon(
                  Icons.password_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Set a new password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  onChanged: vm.updateNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (_) => vm.isPasswordValid
                      ? null
                      : 'Password does not meet all requirements.',
                ),
                const SizedBox(height: 12),
                _Check('At least 8 characters', vm.hasMinLength),
                _Check('Contains uppercase', vm.hasUppercase),
                _Check('Contains lowercase', vm.hasLowercase),
                _Check('Contains number', vm.hasNumber),
                _Check('Contains special character', vm.hasSpecial),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == _passwordCtrl.text
                      ? null
                      : 'Passwords do not match.',
                ),
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                if (vm.successMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    vm.successMessage!,
                    style: const TextStyle(color: AppColors.success),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          if (!widget.recoverySessionVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Open a valid password-reset link from your email.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!_formKey.currentState!.validate()) return;
                          final success = await vm.resetPassword(
                            _passwordCtrl.text,
                          );
                          if (success && context.mounted) {
                            if (widget.wasAuthenticated) {
                              await context.read<AuthViewModel>().finalizeAuthenticatedRecovery();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.profile,
                                (route) => route.settings.name == AppRoutes.treasureMap,
                              );
                            } else {
                              await vm.endRecoverySession();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (route) => false,
                              );
                            }
                          }
                        },
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// D5b. Change Password View (for logged-in users).
class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  late final PasswordRecoveryViewModel _vm;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _vm = PasswordRecoveryViewModel();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<PasswordRecoveryViewModel>(
        builder: (ctx, vm, _) {
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
            appBar: AppBar(title: const Text('Change Password')),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _passwordField(
                      'Current Password',
                      _currentCtrl,
                      _obscureCurrent,
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                      enabled: !vm.isCurrentPasswordVerified,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Current password required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    if (!vm.isCurrentPasswordVerified)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: vm.isLoading
                              ? null
                              : () async {
                                  if (_currentCtrl.text.isEmpty) {
                                    _formKey.currentState!.validate();
                                    return;
                                  }
                                  await vm.verifyCurrentPassword(
                                    _currentCtrl.text,
                                  );
                                },
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Verify current password'),
                        ),
                      )
                    else
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current password verified',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (vm.isCurrentPasswordVerified) ...[
                    _passwordField(
                      'New Password',
                      _newCtrl,
                      _obscureNew,
                      () => setState(() => _obscureNew = !_obscureNew),
                      onChange: _vm.updateNewPassword,
                      validator: (v) => !vm.isPasswordValid
                          ? 'Does not meet requirements'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Checklist
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _Check('At least 8 characters', vm.hasMinLength),
                          _Check('Contains uppercase', vm.hasUppercase),
                          _Check('Contains lowercase', vm.hasLowercase),
                          _Check('Contains number', vm.hasNumber),
                          _Check('Contains special character', vm.hasSpecial),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      'Confirm New Password',
                      _confirmCtrl,
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) =>
                          v != _newCtrl.text ? 'Passwords do not match' : null,
                    ),
                    ],

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (vm.isCurrentPasswordVerified)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: vm.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await _vm.changePassword(
                                  currentPassword: _currentCtrl.text,
                                  newPassword: _newCtrl.text,
                                );
                              },
                          child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        ),
                      ),
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

  Widget _passwordField(
    String label,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggleObscure, {
    Function(String)? onChange,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          enabled: enabled,
          onChanged: onChange,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: toggleObscure,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  final String label;
  final bool met;
  const _Check(this.label, this.met);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: met ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.success : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
