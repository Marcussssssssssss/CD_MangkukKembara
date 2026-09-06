/// App-wide constants for MangkukKembara.
abstract final class AppConstants {
  static const String appName = 'MangkukKembara';
  static const String appTagline = 'Discover Malaysia\'s Heritage';
  static const String appDescription =
      'Explore authentic heritage foods, collect tiffins, '
      'and connect with Malaysia\'s culinary culture.';

  static const int minReviewLength = 3;
  static const int maxReviewLength = 1500;

  static const List<String> malaysianStates = [
    'All States',
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Wilayah Persekutuan KL',
    'Wilayah Persekutuan Labuan',
    'Wilayah Persekutuan Putrajaya',
  ];

  static const List<String> postSortOptions = ['Popular', 'New'];
  static const List<String> artworkSortOptions = [
    'Popular',
    'Most Voted',
    'New',
  ];

  static const int minPasswordLength = 8;
  static const String passwordRequirementsText =
      'Password must be at least 8 characters, contain uppercase, '
      'lowercase, a number, and a special character.';

  static const int pageSize = 10;
  static const int maxPostPhotos = 5;
  static const double maxPhotoSizeMb = 10.0;
}
