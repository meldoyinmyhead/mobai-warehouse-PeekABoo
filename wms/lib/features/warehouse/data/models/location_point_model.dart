class LocationPointModel {
  final double x;
  final double y;
  final int sequenceOrder;
  final String locId;

  LocationPointModel({
    required this.x,
    required this.y,
    required this.sequenceOrder,
    required this.locId,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'sequence_order': sequenceOrder,
      'loc_id': locId,
    };
  }

  factory LocationPointModel.fromMap(Map<String, dynamic> map) {
    return LocationPointModel(
      x: map['x'],
      y: map['y'],
      sequenceOrder: map['sequence_order'],
      locId: map['loc_id'],
    );
  }
}
