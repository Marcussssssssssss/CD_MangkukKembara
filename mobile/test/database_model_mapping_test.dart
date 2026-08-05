import 'package:flutter_test/flutter_test.dart';

import 'package:mangkuk_kembara/Model/Repositories/HeritageExperience/heritage_food_model.dart'
    as experience;
import 'package:mangkuk_kembara/Model/Repositories/HeritageExperience/heritage_media_model.dart';
import 'package:mangkuk_kembara/Model/Repositories/HeritageExperience/heritage_story_model.dart';
import 'package:mangkuk_kembara/Model/Repositories/HeritageExperience/heritage_tiffin_model.dart';
import 'package:mangkuk_kembara/Model/Repositories/HeritageTreasureMap/tiffin_availability_model.dart';

void main() {
  test('heritage experience models map the reset schema identifiers', () {
    final tiffin = HeritageTiffinModel.fromJson({
      'heritage_tiffin_id': 'HT0001',
      'edition_name': 'Penang Edition',
      'description': 'A heritage tiffin.',
      'status': 'active',
      'artwork_id': 'A0001',
      'states': {'state_name': 'Penang', 'state_code': 'PNG'},
      'artworks': {'profile_id': 'P0002'},
    });
    final story = HeritageStoryModel.fromJson({
      'heritage_story_id': 'HS0001',
      'heritage_tiffin_id': 'HT0001',
      'title': 'A story',
      'story_body': 'Story body',
      'sort_order': 1,
    });
    final media = HeritageMediaModel.fromJson({
      'heritage_media_id': 'HM0001',
      'heritage_tiffin_id': 'HT0001',
      'media_type': 'video',
      'title': 'A video',
      'media_url': 'https://example.com/video.mp4',
    });
    final food = experience.HeritageFoodModel.fromJson({
      'heritage_food_id': 'HF0001',
      'food_name': 'Char kway teow',
      'food_categories': {'category_name': 'Noodles'},
      'states': {'state_name': 'Penang'},
    });

    expect(tiffin.id, 'HT0001');
    expect(tiffin.state, 'Penang');
    expect(tiffin.artistId, 'P0002');
    expect(story.tiffinId, 'HT0001');
    expect(media.id, 'HM0001');
    expect(food.name, 'Char kway teow');
    expect(food.categoryName, 'Noodles');
  });

  test('vendor tiffin availability maps heritage_tiffin_id', () {
    final availability = TiffinAvailabilityModel.fromJson({
      'vendor_id': 'V0001',
      'heritage_tiffin_id': 'HT0001',
      'availability_status': 'available',
      'heritage_tiffins': {'edition_name': 'Penang Edition'},
    });

    expect(availability.vendorId, 'V0001');
    expect(availability.tiffinId, 'HT0001');
    expect(availability.tiffinEditionName, 'Penang Edition');
    expect(availability.isAvailable, isTrue);
  });
}
