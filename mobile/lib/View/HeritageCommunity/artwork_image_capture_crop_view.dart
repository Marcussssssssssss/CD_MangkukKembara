import 'package:camera/camera.dart' hide XFile;
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';

Future<XFile> convertArtworkImageToWebP(
  XFile source, {
  double? aspectRatio,
}) async {
  final bytes = await source.readAsBytes();
  final converted = await compute(_encodeArtworkWebP, (
    bytes: bytes,
    aspectRatio: aspectRatio,
  ));
  return XFile.fromData(
    converted,
    name: 'artwork_${DateTime.now().millisecondsSinceEpoch}.webp',
    mimeType: 'image/webp',
  );
}

Uint8List _encodeArtworkWebP(({Uint8List bytes, double? aspectRatio}) request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) {
    throw const FormatException('The selected image format is not supported.');
  }

  var output = decoded;
  if (request.aspectRatio == 5) {
    final targetHeight = decoded.height < decoded.width ~/ 5
        ? decoded.height
        : decoded.width ~/ 5;
    final targetWidth = targetHeight * 5;
    if (targetWidth <= 0 || targetHeight <= 0) {
      throw const FormatException('The selected image is too small.');
    }
    if (decoded.width != targetWidth || decoded.height != targetHeight) {
      output = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  return img.encodeWebP(output);
}

class ArtworkCameraCaptureView extends StatefulWidget {
  final String title;
  final double aspectRatio;

  const ArtworkCameraCaptureView({
    super.key,
    required this.title,
    required this.aspectRatio,
  });

  @override
  State<ArtworkCameraCaptureView> createState() =>
      _ArtworkCameraCaptureViewState();
}

class _ArtworkCameraCaptureViewState extends State<ArtworkCameraCaptureView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'No camera is available.');
        return;
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _error = _cameraErrorMessage(error));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final captured = await controller.takePicture();
      if (mounted) Navigator.pop(context, XFile(captured.path));
    } on CameraException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cameraErrorMessage(error))));
        setState(() => _isCapturing = false);
      }
    }
  }

  String _cameraErrorMessage(CameraException error) => switch (error.code) {
    'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' =>
      'Camera access is required to take this photo.',
    _ => 'The camera could not be opened. ${error.description ?? ''}'.trim(),
  };

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : controller == null || !controller.value.isInitialized
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: AspectRatio(
                          aspectRatio: widget.aspectRatio,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _CoverCameraPreview(controller: controller),
                                const _RatioGuideOverlay(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Fit the complete design inside the highlighted frame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: .8)),
                  ),
                  const SizedBox(height: 14),
                  IconButton.filled(
                    onPressed: _isCapturing ? null : _capture,
                    iconSize: 34,
                    padding: const EdgeInsets.all(16),
                    icon: _isCapturing
                        ? const SizedBox.square(
                            dimension: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtworkImageCropView extends StatefulWidget {
  final XFile sourceFile;
  final String title;
  final double aspectRatio;

  const ArtworkImageCropView({
    super.key,
    required this.sourceFile,
    required this.title,
    required this.aspectRatio,
  });

  @override
  State<ArtworkImageCropView> createState() => _ArtworkImageCropViewState();
}

class _ArtworkImageCropViewState extends State<ArtworkImageCropView> {
  final CropController _cropController = CropController();
  Uint8List? _imageBytes;
  String? _error;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.sourceFile.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The selected image could not be read.');
      }
    }
  }

  Future<void> _onCropped(CropResult result) async {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final file = await convertArtworkImageToWebP(
            XFile.fromData(croppedImage, name: 'cropped-image'),
            aspectRatio: widget.aspectRatio,
          );
          if (mounted) Navigator.pop(context, file);
        } catch (_) {
          if (mounted) {
            setState(() {
              _isCropping = false;
              _error = 'This image format could not be converted to WebP.';
            });
          }
        }
      case CropFailure(:final cause):
        setState(() {
          _isCropping = false;
          _error = 'Cropping failed: $cause';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _imageBytes;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Crop ${widget.title}'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: bytes == null || _isCropping
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _cropController.crop();
                  },
            child: const Text('USE PHOTO'),
          ),
        ],
      ),
      body: SafeArea(
        child: bytes == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
              )
            : Stack(
                children: [
                  Crop(
                    image: bytes,
                    controller: _cropController,
                    aspectRatio: widget.aspectRatio,
                    initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                      size: .9,
                      aspectRatio: widget.aspectRatio,
                    ),
                    interactive: true,
                    fixCropRect: true,
                    baseColor: Colors.black,
                    maskColor: Colors.black.withValues(alpha: .7),
                    progressIndicator: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    overlayBuilder: (_, _) => const _RatioGuideOverlay(),
                    onCropped: _onCropped,
                  ),
                  if (_isCropping)
                    const ColoredBox(
                      color: Colors.black45,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  if (_error != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CoverCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize!;
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final width = portrait ? previewSize.height : previewSize.width;
    final height = portrait ? previewSize.width : previewSize.height;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _RatioGuideOverlay extends StatelessWidget {
  const _RatioGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
