import 'package:wms/features/inventory/data/models/entrepot_model.dart';
import 'package:wms/core/data/repositories/base_repository_impl.dart';

class EntrepotRepository extends BaseRepositoryImpl<EntrepotModel> {
  EntrepotRepository() : super('entrepots');

  @override
  EntrepotModel fromMap(Map<String, dynamic> map) {
    return EntrepotModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(EntrepotModel item) {
    return item.toMap();
  }
}
