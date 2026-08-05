import 'package:flutter/material.dart';

import '../../Model/Repositories/AccountManagement/account_repository.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../Widgets/auth_branding.dart';

class EmailVerificationView extends StatefulWidget {
  final String email;

  const EmailVerificationView({super.key, required this.email});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  final _repository = AccountRepository();
  bool _resending = false;

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      await _repository.resendVerificationEmail(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent again.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const AuthBranding(subtitle: 'Email verification'),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.mark_email_unread_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Check your inbox',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We sent a confirmation link to:',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            widget.email,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Open the link in that email, then return here and log in. Your account is not signed in until verification is complete.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.login,
                                    (route) =>
                                        route.settings.name ==
                                        AppRoutes.treasureMap,
                                  ),
                              child: const Text('Return to Login'),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _resending ? null : _resend,
                            icon: _resending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded),
                            label: const Text('Resend verification email'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
