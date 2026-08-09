/// A heritage tiffin design carried by a vendor.
class VendorTiffinModel {
  final String vendorId;
  final String tiffinId;
  final String tiffinEditionName;
  final String? coverImageUrl;

  const VendorTiffinModel({
    required this.vendorId,
    required this.tiffinId,
    required this.tiffinEditionName,
    this.coverImageUrl,
  });

  factory VendorTiffinModel.fromJson(Map<String, dynamic> json) {
    final tiffin = json['heritage_tiffins'] as Map<String, dynamic>?;
    return VendorTiffinModel(
      vendorId: json['vendor_id'] as String,
      tiffinId: json['heritage_tiffin_id'] as String,
      tiffinEditionName: tiffin?['edition_name'] as String? ?? '',
      coverImageUrl: tiffin?['cover_image_url'] as String?,
    );
  }
}
