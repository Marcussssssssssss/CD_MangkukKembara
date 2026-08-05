/// Operating hours for a vendor on a given day.
class OperatingHourModel {
  final String vendorId;
  final String dayName; // e.g. 'Monday'
  final String? openTime; // e.g. '08:00'
  final String? closeTime; // e.g. '22:00'
  final bool isClosed;

  const OperatingHourModel({
    required this.vendorId,
    required this.dayName,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory OperatingHourModel.fromJson(Map<String, dynamic> json) {
    const names = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final day = (json['day_of_week'] as num).toInt();
    return OperatingHourModel(
      vendorId: json['vendor_id'] as String,
      dayName: names[day],
      openTime: (json['opening_time'] as String?)?.substring(0, 5),
      closeTime: (json['closing_time'] as String?)?.substring(0, 5),
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  String get displayHours {
    if (isClosed) return 'Closed';
    if (openTime == null || closeTime == null) return 'Hours not available';
    return '$openTime – $closeTime';
  }
}
