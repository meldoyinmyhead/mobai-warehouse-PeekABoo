import 'dart:convert';

class WarehouseModel {
  final String id;
  final String code;
  final String name;
  final String? address;
  final String city;
  final String? openingHours;
  final String? managerId;
  final double width;
  final double length;
  final double height;
  final String? climateType;
  final bool isActive;
  final Map<String, dynamic>? layoutMap;
  final List<FloorModel> floors;

  WarehouseModel({
    required this.id,
    required this.code,
    required this.name,
    this.address,
    required this.city,
    this.openingHours,
    this.managerId,
    this.width = 0.0,
    this.length = 0.0,
    this.height = 0.0,
    this.climateType,
    this.isActive = true,
    this.layoutMap,
    this.floors = const [],
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id_entrepot'] ?? '',
      code: json['code_entrepot'] ?? '',
      name: json['nom_entrepot'] ?? '',
      address: json['adresse'],
      city: json['ville'] ?? '',
      openingHours: json['heures_ouverture'],
      managerId: json['manager_id'],
      width: (json['largeur'] as num?)?.toDouble() ?? 0.0,
      length: (json['longueur'] as num?)?.toDouble() ?? 0.0,
      height: (json['hauteur'] as num?)?.toDouble() ?? 0.0,
      climateType: json['type_climat'],
      isActive: json['actif'] ?? true,
      layoutMap: json['layout_map'],
      floors: (json['etages'] as List? ?? [])
          .map((i) => FloorModel.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_entrepot': id,
      'code_entrepot': code,
      'nom_entrepot': name,
      'adresse': address,
      'ville': city,
      'heures_ouverture': openingHours,
      'manager_id': managerId,
      'largeur': width,
      'longueur': length,
      'hauteur': height,
      'type_climat': climateType,
      'actif': isActive,
      'layout_map': layoutMap,
    };
  }
}

class FloorModel {
  final String id;
  final String warehouseId;
  final String name;
  final String code;
  final int locationCount;

  FloorModel({
    required this.id,
    required this.warehouseId,
    required this.name,
    required this.code,
    this.locationCount = 0,
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] ?? '',
      warehouseId: json['id_entrepot'] ?? '',
      name: json['nom_etage'] ?? '',
      code: json['code_etage'] ?? '',
      locationCount: json['nombre_emplacements'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_entrepot': warehouseId,
      'nom_etage': name,
      'code_etage': code,
      'nombre_emplacements': locationCount,
    };
  }
}
