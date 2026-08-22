/// Abstract interface for file upload/download operations.
abstract class StorageRepository {
  /// Upload a file and return its download URL
  Future<String> uploadFile({
    required String path,
    required List<int> bytes,
    String? contentType,
  });

  /// Delete a file
  Future<void> deleteFile(String path);

  /// Get download URL for a file
  Future<String> getDownloadUrl(String path);
}
