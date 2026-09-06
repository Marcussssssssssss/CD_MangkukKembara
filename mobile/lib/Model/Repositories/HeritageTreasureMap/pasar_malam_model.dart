/// Parent night-market location shown as one marker on the Treasure Map.
class PasarMalamOperatingHourModel {
  final int dayOfWeek;
  final String dayName;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  const PasarMalamOperatingHourModel({
    required this.dayOfWeek,
    required this.dayName,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory PasarMalamOperatingHourModel.fromJson(Map<String, dynamic> json) {
    const dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final day = (json['day_of_week'] as num).toInt();
    final openingTime = json['opening_time'] as String?;
    final closingTime = json['closing_time'] as String?;

    return PasarMalamOperatingHourModel(
      dayOfWeek: day,
      dayName: dayNames[day],
      openTime: _displayTime(openingTime),
      closeTime: _displayTime(closingTime),
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  String get displayHours {
    if (isClosed) return 'Closed';
    if (openTime == null || closeTime == null) return 'Hours not available';
    return '$openTime – $closeTime';
  }

  static String? _displayTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class PasarMalamModel {
  final String id;
  final String name;
  final String description;
  final String state;
  final String address;
  final String? contactNumber;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final List<PasarMalamOperatingHourModel> operatingHours;
  final int activeVendorCount;

  const PasarMalamModel({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.contactNumber,
    this.isOpen = false,
    this.operatingHours = const [],
    this.activeVendorCount = 0,
  });

  factory PasarMalamModel.fromJson(Map<String, dynamic> json) {
    final state = json['states'] as Map<String, dynamic>?;
    final addressParts = <String?>[
      json['address_line'] as String?,
      state?['state_name'] as String?,
    ].whereType<String>().where((part) => part.trim().isNotEmpty);
    final operatingHours =
        (json['pasar_malam_operating_hours'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PasarMalamOperatingHourModel.fromJson)
            .toList()
          ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final activeVendorCount = (json['vendors'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((vendor) => vendor['participation_status'] == 'active')
        .length;

    return PasarMalamModel(
      id: json['pasar_malam_id'] as String,
      name: json['pasar_malam_name'] as String,
      description: json['description'] as String? ?? '',
      state: state?['state_name'] as String? ?? '',
      address: addressParts.join(', '),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isOpen: json['_is_open'] as bool? ?? false,
      operatingHours: operatingHours,
      activeVendorCount: activeVendorCount,
    );
  }
}
