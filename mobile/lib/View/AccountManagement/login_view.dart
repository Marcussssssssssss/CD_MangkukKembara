import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../core/app_routes.dart';

/// A heritage-travel login page that keeps the existing authentication flow.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    vm.clearError();
    final ok = await vm.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.treasureMap,
        (_) => false,
      );
    }
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

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
    child: Consumer<AuthViewModel>(
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
                            const SizedBox(height: 46),
                            Center(
                              child: Image.asset(
                                'asset/image/mangkuk_kembara_logo_white.png',
                                width: 250,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome Back',
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
                              'Continue your heritage food journey.',
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
                                        hint: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscurePassword,
                                        action: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        onSubmitted: (_) => _login(vm),
                                        suffix: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          color: const Color(0xFFFFD47B),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Password is required'
                                            : null,
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.forgotPassword,
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFFFD47B,
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                              bottom: 6,
                                            ),
                                            textStyle: GoogleFonts.dmSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: const Color(
                                                0xFFFFD47B,
                                              ),
                                            ),
                                          ),
                                          child: const Text('Forgot password?'),
                                        ),
                                      ),
                                      if (vm.errorMessage
                                          case final message?) ...[
                                        const SizedBox(height: 4),
                                        _LoginError(message: message),
                                      ],
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 256,
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
                                                : () => _login(vm),
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
                                                    'Login',
                                                    style:
                                                        GoogleFonts.playfairDisplay(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
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
                                AppRoutes.register,
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
                              child: const Text('New to Mangkuk Kembara?'),
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
  );
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
    this.onSubmitted,
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
  final ValueChanged<String>? onSubmitted;

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
    onFieldSubmitted: onSubmitted,
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

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

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
