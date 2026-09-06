import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/email_address_validator.dart';
import '../../ViewModel/AccountManagement/email_change_view_model.dart';

class ChangeEmailDialog extends StatefulWidget {
  final String currentEmail;

  const ChangeEmailDialog({super.key, required this.currentEmail});

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final EmailChangeViewModel _viewModel;
  bool _obscurePassword = true;
  bool _isOtpStep = false;
  bool _isCurrentEmailOtpStep = false;
  String? _pendingEmail;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = EmailChangeViewModel();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final pendingEmail = await _viewModel.requestChange(
      newEmail: _emailController.text,
      currentPassword: _passwordController.text,
    );
    _passwordController.clear();
    if (pendingEmail != null && mounted) {
      setState(() {
        _pendingEmail = pendingEmail;
        _isOtpStep = true;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate() || _pendingEmail == null) return;
    final verified = await _viewModel.verifyEmailOtp(
      email: _isCurrentEmailOtpStep ? widget.currentEmail : _pendingEmail!,
      token: _otpController.text,
    );
    if (!verified || !mounted) return;
    if (!_isCurrentEmailOtpStep) {
      _otpController.clear();
      setState(() => _isCurrentEmailOtpStep = true);
      return;
    }
    Navigator.pop(context, _pendingEmail);
  }

  Future<void> _resendOtp() async {
    final email = _isCurrentEmailOtpStep
        ? widget.currentEmail
        : _pendingEmail;
    if (email == null) return;
    await _viewModel.resendEmailOtp(email: email);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<EmailChangeViewModel>(
        builder: (context, viewModel, _) => AlertDialog(
          title: Text(
            !_isOtpStep
                ? 'Change email address'
                : _isCurrentEmailOtpStep
                ? 'Verify current email'
                : 'Verify new email',
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOtpStep
                        ? _isCurrentEmailOtpStep
                            ? 'Enter the OTP sent to ${widget.currentEmail} to complete the email change.'
                            : 'Enter the OTP sent to $_pendingEmail. Then enter the separate OTP sent to ${widget.currentEmail}.'
                        : 'Your current email (${widget.currentEmail}) stays active until the new address is verified.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  if (!_isOtpStep) ...[
                    TextFormField(
                      controller: _emailController,
                      enabled: !viewModel.isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.newUsername],
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(
                        labelText: 'New email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) =>
                          EmailAddressValidator.validateChange(
                            value,
                            currentEmail: widget.currentEmail,
                          ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !viewModel.isSubmitting,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: viewModel.isSubmitting
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Current password is required'
                          : null,
                    ),
                  ] else
                    TextFormField(
                      controller: _otpController,
                      enabled: !viewModel.isSubmitting,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verifyOtp(),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP',
                        prefixIcon: Icon(Icons.password_rounded),
                        counterText: '',
                      ),
                      validator: (value) =>
                          value == null || value.trim().length != 6
                          ? 'Enter the 6-digit OTP'
                          : null,
                    ),
                  if (_isOtpStep)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: viewModel.isSubmitting ? null : _resendOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: viewModel.isSubmitting
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: viewModel.isSubmitting
                  ? null
                  : _isOtpStep
                  ? _verifyOtp
                  : _submit,
              child: viewModel.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      !_isOtpStep
                          ? 'Send OTP'
                          : _isCurrentEmailOtpStep
                          ? 'Complete change'
                          : 'Verify new email',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
