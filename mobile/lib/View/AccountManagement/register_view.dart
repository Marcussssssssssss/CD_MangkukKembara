import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../ViewModel/AccountManagement/register_view_model.dart';
import '../Widgets/auth_branding.dart';

/// D4. Register View.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final RegisterViewModel _vm;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  DateTime? _dateOfBirth;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _vm = RegisterViewModel();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<RegisterViewModel>(
        builder: (ctx, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: AuthBranding(subtitle: 'Create your account'),
                      ),
                      const SizedBox(height: 28),
                      _label('Display Name *'),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'How should we call you?',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Display name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _label('Email *'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Your email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                          ).hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _label('Password *'),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Create a strong password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        onChanged: _vm.updatePassword,
                        validator: (v) => !vm.isPasswordValid
                            ? 'Password does not meet requirements'
                            : null,
                      ),
                      const SizedBox(height: 8),

                      // Password policy checklist
                      _PasswordPolicyChecklist(vm: vm),
                      const SizedBox(height: 16),

                      _label('Confirm Password *'),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Repeat your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (v) => v != _passwordCtrl.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Optional fields
                      _label('Country Code (optional)'),
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

                      _label('City (optional)'),
                      TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Kuala Lumpur',
                          prefixIcon: Icon(Icons.location_city_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Date of Birth (optional)'),
                      ListTile(
                        tileColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: const Icon(Icons.cake_outlined),
                        title: Text(
                          _dateOfBirth == null
                              ? 'Select date of birth'
                              : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final selected = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime(now.year - 120),
                            lastDate: DateTime(
                              now.year - 13,
                              now.month,
                              now.day,
                            ),
                            initialDate:
                                _dateOfBirth ?? DateTime(now.year - 18),
                          );
                          if (selected != null) {
                            setState(() => _dateOfBirth = selected);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      _label('Gender (optional)'),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'non_binary',
                            child: Text('Non-binary'),
                          ),
                          DropdownMenuItem(
                            value: 'prefer_not_to_say',
                            child: Text('Prefer not to say'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 24),

                      if (vm.errorMessage != null) ...[
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
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: vm.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final ok = await _vm.register(
                                    displayName: _nameCtrl.text.trim(),
                                    email: _emailCtrl.text.trim(),
                                    password: _passwordCtrl.text,
                                    country: _countryCtrl.text.trim().isEmpty
                                        ? null
                                        : _countryCtrl.text.trim(),
                                    city: _cityCtrl.text.trim().isEmpty
                                        ? null
                                        : _cityCtrl.text.trim(),
                                    dateOfBirth: _dateOfBirth,
                                    gender: _gender,
                                  );
                                  if (ok && ctx.mounted) {
                                    await _showVerificationDialog(ctx, vm);
                                  }
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              ctx,
                              AppRoutes.login,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _showVerificationDialog(
    BuildContext context,
    RegisterViewModel vm,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_unread_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            title: const Text('Check your inbox'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We sent an email confirmation link to:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  vm.registeredEmail ?? _emailCtrl.text.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verify that address before logging in. Registration does not sign you into the application.',
                  textAlign: TextAlign.center,
                ),
                if (vm.resendMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.resendMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.success),
                  ),
                ],
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton.icon(
                onPressed: vm.isResending
                    ? null
                    : () async {
                        final resend = vm.resendVerificationEmail();
                        setDialogState(() {});
                        await resend;
                        if (dialogContext.mounted) setDialogState(() {});
                      },
                icon: vm.isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Resend email'),
              ),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  dialogContext,
                  AppRoutes.login,
                  (_) => false,
                ),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
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

class _PasswordPolicyChecklist extends StatelessWidget {
  final RegisterViewModel vm;
  const _PasswordPolicyChecklist({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _Check(
            'At least ${AppConstants.minPasswordLength} characters',
            vm.hasMinLength,
          ),
          _Check('Contains uppercase letter', vm.hasUppercase),
          _Check('Contains lowercase letter', vm.hasLowercase),
          _Check('Contains number', vm.hasNumber),
          _Check('Contains special character (!@#\$...)', vm.hasSpecial),
        ],
      ),
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
