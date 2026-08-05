/// QR scan result after validating and collecting a tiffin QR code.
class QrScanResultModel {
  final String tiffinId;
  final String editionName;
  final bool isNewlyCollected; // false = already in collection
  final String state;

  const QrScanResultModel({
    required this.tiffinId,
    required this.editionName,
    required this.isNewlyCollected,
    required this.state,
  });

  factory QrScanResultModel.fromJson(
    Map<String, dynamic> rpc,
    Map<String, dynamic> tiffin,
  ) {
    final state = tiffin['states'] as Map<String, dynamic>?;
    return QrScanResultModel(
      tiffinId: rpc['heritage_tiffin_id'] as String,
      editionName: tiffin['edition_name'] as String,
      isNewlyCollected: rpc['newly_collected'] as bool? ?? false,
      state: state?['state_name'] as String? ?? '',
    );
  }
}
