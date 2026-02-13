import 'package:wms/features/inventory/data/models/emplacement_model.dart';
import 'package:wms/core/data/repositories/base_repository_impl.dart';

class EmplacementRepository extends BaseRepositoryImpl<EmplacementModel> {
  EmplacementRepository() : super('emplacements');

  @override
  EmplacementModel fromMap(Map<String, dynamic> map) {
    return EmplacementModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(EmplacementModel item) {
    return item.toMap();
  }
}
