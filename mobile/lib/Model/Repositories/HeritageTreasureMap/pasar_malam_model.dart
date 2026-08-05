/// Parent night-market location shown as one marker on the Treasure Map.
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
  });

  factory PasarMalamModel.fromJson(Map<String, dynamic> json) {
    final state = json['states'] as Map<String, dynamic>?;
    final addressParts = <String?>[
      json['address_line'] as String?,
      state?['state_name'] as String?,
    ].whereType<String>().where((part) => part.trim().isNotEmpty);
    return PasarMalamModel(
      id: json['pasar_malam_id'] as String,
      name: json['pasar_malam_name'] as String,
      description: json['description'] as String? ?? '',
      state: state?['state_name'] as String? ?? '',
      address: addressParts.join(', '),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isOpen: json['_is_open'] as bool? ?? false,
    );
  }
}
