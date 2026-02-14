class LocationPointModel {
  final double x;
  final double y;
  final double z; // Level/Floor
  final int sequenceOrder;
  final String locId;

  LocationPointModel({
    required this.x,
    required this.y,
    this.z = 0,
    required this.sequenceOrder,
    required this.locId,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'sequence_order': sequenceOrder,
      'loc_id': locId,
    };
  }

  factory LocationPointModel.fromMap(Map<String, dynamic> map) {
    return LocationPointModel(
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      z: map['z']?.toDouble() ?? 0.0,
      sequenceOrder: map['sequence_order'] ?? 0,
      locId: map['loc_id'] ?? '',
    );
  }
}
