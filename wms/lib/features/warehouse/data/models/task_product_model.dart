class TaskProductModel {
  final String productId;
  final String name;
  final int expectedQuantity;
  final int actualQuantity;
  final bool isFragile;

  TaskProductModel({
    required this.productId,
    required this.name,
    required this.expectedQuantity,
    this.actualQuantity = 0,
    this.isFragile = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'expected_quantity': expectedQuantity,
      'actual_quantity': actualQuantity,
      'is_fragile': isFragile ? 1 : 0,
    };
  }

  factory TaskProductModel.fromMap(Map<String, dynamic> map) {
    return TaskProductModel(
      productId: map['product_id'] ?? '',
      name: map['name'] ?? '',
      expectedQuantity: map['expected_quantity'] ?? 0,
      actualQuantity: map['actual_quantity'] ?? 0,
      isFragile: map['is_fragile'] == 1,
    );
  }
}
