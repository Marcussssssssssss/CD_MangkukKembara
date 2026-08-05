import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/HeritageExperience/qr_scanner_view_model.dart';

/// B2. Authenticated QR scanner backed by scan_tiffin_qr().
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  late final QrScannerViewModel _vm;
  late final MobileScannerController _controller;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _vm = QrScannerViewModel();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture, AuthViewModel auth) async {
    if (_processing || auth.currentUser == null) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.trim().isEmpty) return;
    _processing = true;
    await _controller.stop();
    await _vm.processScan(auth.currentUser!.id, value);
    if (!mounted) return;
    if (_vm.result != null) {
      await Navigator.pushReplacementNamed(
        context,
        AppRoutes.scanResult,
        arguments: _vm.result,
      );
      return;
    }
    _processing = false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<QrScannerViewModel, AuthViewModel>(
        builder: (context, vm, auth, _) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Scan Heritage Tiffin'),
            actions: [
              IconButton(
                tooltip: 'Toggle flashlight',
                onPressed: auth.isLoggedIn ? _controller.toggleTorch : null,
                icon: const Icon(Icons.flashlight_on_rounded),
              ),
            ],
          ),
          body: !auth.isLoggedIn
              ? _authenticationRequired(context)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: (capture) => _onDetect(capture, auth),
                      errorBuilder: (_, error) => _cameraError(error),
                    ),
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        minimum: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: vm.state == QrScanState.scanning
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Adding tiffin to your collection…',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                )
                              : vm.state == QrScanState.error
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      vm.errorMessage ??
                                          'Unable to scan this QR code.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        vm.reset();
                                        _processing = false;
                                        await _controller.start();
                                      },
                                      child: const Text('Try again'),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Point the camera at the tiffin QR code',
                                  style: TextStyle(color: Colors.white),
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

  Widget _authenticationRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 52,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Login is required to add a tiffin to your collection.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.login,
                arguments: AppRoutes.qrScanner,
              ),
              child: const Text('Login / Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraError(MobileScannerException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
