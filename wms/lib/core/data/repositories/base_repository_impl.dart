abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> insert(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}

abstract class BaseRepositoryImpl<T> implements BaseRepository<T> {
  final String tableName;

  BaseRepositoryImpl(this.tableName);

  // Abstract method to map Map<String, dynamic> to T
  T fromMap(Map<String, dynamic> map);

  // Abstract method to map T to Map<String, dynamic>
  Map<String, dynamic> toMap(T item);

  @override
  Future<List<T>> getAll() async {
    // Legacy support, migration to Drift planned
    return [];
  }

  @override
  Future<T?> getById(String id) async {
    return null;
  }

  @override
  Future<void> insert(T item) async {
  }

  @override
  Future<void> update(T item) async {
  }

  @override
  Future<void> delete(String id) async {
  }
}
