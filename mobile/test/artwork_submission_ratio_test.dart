import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mangkuk_kembara/View/HeritageCommunity/artwork_image_capture_crop_view.dart';
import 'package:mangkuk_kembara/ViewModel/HeritageCommunity/artwork_submission_view_model.dart';

void main() {
  group('tiffin layer image ratio', () {
    test('submission requires one front view and three layer views', () {
      expect(ArtworkPhotoView.values, hasLength(4));
      expect(ArtworkPhotoView.values.first, ArtworkPhotoView.frontHero);
    });

    test('accepts 5:1 images at recommended export sizes', () {
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.layer1Flat360,
          1500,
          300,
        ),
        isTrue,
      );
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.layer2Flat360,
          2500,
          500,
        ),
        isTrue,
      );
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.layer3Flat360,
          3000,
          600,
        ),
        isTrue,
      );
    });

    test('rejects non-5:1 and invalid image dimensions', () {
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.layer1Flat360,
          2500,
          501,
        ),
        isFalse,
      );
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.layer1Flat360,
          1600,
          900,
        ),
        isFalse,
      );
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.layer1Flat360,
          0,
          0,
        ),
        isFalse,
      );
    });

    test('the front assembled view accepts any positive aspect ratio', () {
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.frontHero,
          1600,
          2000,
        ),
        isTrue,
      );
      expect(
        ArtworkSubmissionViewModel.isValidDimensions(
          ArtworkPhotoView.frontHero,
          1000,
          800,
        ),
        isTrue,
      );
    });

    test(
      'front images keep their original ratio when converted to WebP',
      () async {
        final sourceBytes = img.encodeBmp(img.Image(width: 320, height: 123));
        final converted = await convertArtworkImageToWebP(
          XFile.fromData(sourceBytes, name: 'front.bmp'),
        );
        final decoded = img.decodeImage(await converted.readAsBytes());

        expect(converted.mimeType, 'image/webp');
        expect(decoded?.width, 320);
        expect(decoded?.height, 123);
      },
    );

    test(
      'layer WebP conversion normalizes crop rounding to exact 5:1',
      () async {
        final sourceBytes = img.encodePng(img.Image(width: 2501, height: 500));
        final converted = await convertArtworkImageToWebP(
          XFile.fromData(sourceBytes, name: 'layer.png'),
          aspectRatio: ArtworkSubmissionViewModel.layerAspectRatio,
        );
        final decoded = img.decodeImage(await converted.readAsBytes());

        expect(decoded?.width, 2500);
        expect(decoded?.height, 500);
      },
    );
  });
}
