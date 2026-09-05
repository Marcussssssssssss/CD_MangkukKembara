import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/AccountManagement/register_view_model.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';

/// Registration screen styled to match the heritage-travel login screen.
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
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    super.dispose();
  }

  void _back() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.accountLanding,
        (route) => route.isFirst,
      );
    }
  }

  Future<void> _register(RegisterViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await vm.register(
      displayName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (ok && mounted) await _showVerificationDialog(context, vm);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
    child: ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<RegisterViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: const Color(0xFF007D7D),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const Image(
                image: AssetImage('asset/image/welcome_base_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xA6004648),
                      Color(0x8F004B4D),
                      Color(0xBD003E41),
                    ],
                    stops: [0, .46, 1],
                  ),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      36,
                      4,
                      36,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 30),
                              Center(
                                child: Image.asset(
                                  'asset/image/mangkuk_kembara_logo_white.png',
                                  width: 250,
                                ),
                              ),
                              const SizedBox(height: 0),
                              Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFFFF8EC),
                                  fontSize: 30,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x80003638),
                                      offset: Offset(0, 2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Begin your heritage food journey.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFFFF8EC),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Form(
                                key: _formKey,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 256,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _HeritageField(
                                          controller: _nameCtrl,
                                          hint: 'Name',
                                          icon: Icons.person_outline_rounded,
                                          action: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          validator: (value) =>
                                              value == null ||
                                                  value.trim().isEmpty
                                              ? 'Name is required'
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        _HeritageField(
                                          controller: _emailCtrl,
                                          hint: 'Email address',
                                          icon: Icons.mail_outline_rounded,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          action: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.email,
                                          ],
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Email is required';
                                            }
                                            if (!RegExp(
                                              r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                            ).hasMatch(value)) {
                                              return 'Enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _HeritageField(
                                          controller: _passwordCtrl,
                                          hint: 'Create password',
                                          icon: Icons.lock_outline_rounded,
                                          obscure: _obscurePassword,
                                          action: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                          suffix: _VisibilityButton(
                                            obscure: _obscurePassword,
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                          ),
                                          onChanged: vm.updatePassword,
                                          validator: (value) =>
                                              !vm.isPasswordValid
                                              ? 'Password does not meet requirements'
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        _PasswordPolicyChecklist(vm: vm),
                                        const SizedBox(height: 12),
                                        _HeritageField(
                                          controller: _confirmCtrl,
                                          hint: 'Confirm password',
                                          icon: Icons.lock_outline_rounded,
                                          obscure: _obscureConfirm,
                                          action: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.newPassword,
                                          ],
                                          suffix: _VisibilityButton(
                                            obscure: _obscureConfirm,
                                            onPressed: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                          ),
                                          validator: (value) =>
                                              value != _passwordCtrl.text
                                              ? 'Passwords do not match'
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        if (vm.errorMessage
                                            case final message?) ...[
                                          const SizedBox(height: 12),
                                          _RegisterError(message: message),
                                        ],
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          height: 40,
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFFFF8EC,
                                              ),
                                              foregroundColor: const Color(
                                                0xFF075A5A,
                                              ),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: vm.isLoading
                                                ? null
                                                : () => _register(vm),
                                            child: vm.isLoading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color: Color(
                                                            0xFF075A5A,
                                                          ),
                                                        ),
                                                  )
                                                : Text(
                                                    'Create Account',
                                                    style:
                                                        GoogleFonts.playfairDisplay(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFF8EC),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  textStyle: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFFFFD47B),
                                  ),
                                ),
                                child: const Text('Already have an account?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                    ),
                    Positioned(
                      left: 36,
                      top: 12,
                      child: _RoundBackButton(onPressed: _back),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
              color: Color(0xFF075A5A),
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
                    style: const TextStyle(color: Color(0xFF13875C)),
                  ),
                ],
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFC93E3A)),
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
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x26003F42),
    shape: const CircleBorder(
      side: BorderSide(color: Color(0x73FFF8EC), width: 1),
    ),
    child: IconButton(
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
      tooltip: 'Back',
      onPressed: onPressed,
      color: const Color(0xFFFFF8EC),
      icon: const Icon(Icons.arrow_back_rounded),
    ),
  );
}

class _HeritageField extends StatelessWidget {
  const _HeritageField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.action,
    this.autofillHints,
    this.obscure = false,
    this.suffix,
    this.onChanged,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  OutlineInputBorder _border(Color color, [double width = 1.4]) =>
      OutlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
        borderRadius: BorderRadius.circular(17),
      );

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: action,
    autofillHints: autofillHints,
    obscureText: obscure,
    onChanged: onChanged,
    maxLength: maxLength,
    textCapitalization: textCapitalization,
    cursorColor: const Color(0xFFFFD47B),
    validator: validator,
    style: GoogleFonts.dmSans(
      color: const Color(0xFFFFF8EC),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        color: const Color(0xBFF5F2E5),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFFFFD47B)),
      suffixIcon: suffix,
      counterText: '',
      isDense: true,
      filled: true,
      fillColor: const Color(0xBD004B4D),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: _border(const Color(0xD9FFC95C)),
      focusedBorder: _border(const Color(0xFFFFE292), 2),
      errorBorder: _border(const Color(0xFFFFA09A)),
      focusedErrorBorder: _border(const Color(0xFFFFA09A), 2),
      errorStyle: GoogleFonts.dmSans(
        color: const Color(0xFFFFD3CD),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.obscure, required this.onPressed});

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: obscure ? 'Show password' : 'Hide password',
    color: const Color(0xFFFFD47B),
    onPressed: onPressed,
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
  );
}

class _PasswordPolicyChecklist extends StatelessWidget {
  const _PasswordPolicyChecklist({required this.vm});

  final RegisterViewModel vm;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0x80003F42),
      border: Border.all(color: const Color(0x70FFF8EC)),
      borderRadius: BorderRadius.circular(12),
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

class _Check extends StatelessWidget {
  const _Check(this.label, this.met);

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 14,
          color: met ? const Color(0xFF8FE1B8) : const Color(0xBFF5F2E5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: met ? const Color(0xFFB8F1D4) : const Color(0xBFF5F2E5),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RegisterError extends StatelessWidget {
  const _RegisterError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xCC722C2B),
      border: Border.all(color: const Color(0xFFFFB0A8)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFFFD3CD),
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.dmSans(
              color: const Color(0xFFFFF8EC),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
