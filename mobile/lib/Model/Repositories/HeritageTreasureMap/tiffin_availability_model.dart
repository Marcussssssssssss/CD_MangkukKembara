/// Tiffin availability at a vendor — links vendor to a heritage tiffin.
class TiffinAvailabilityModel {
  final String vendorId;
  final String tiffinId;
  final String tiffinEditionName;
  final bool isAvailable;
  final String? notes;

  const TiffinAvailabilityModel({
    required this.vendorId,
    required this.tiffinId,
    required this.tiffinEditionName,
    required this.isAvailable,
    this.notes,
  });

  factory TiffinAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final tiffin = json['heritage_tiffins'] as Map<String, dynamic>?;
    return TiffinAvailabilityModel(
      vendorId: json['vendor_id'] as String,
      tiffinId: json['heritage_tiffin_id'] as String,
      tiffinEditionName: tiffin?['edition_name'] as String? ?? '',
      isAvailable: json['availability_status'] != 'unavailable',
      notes: null,
    );
  }
}
