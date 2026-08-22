import '../models/product.dart';

/// Abstract interface for product CRUD and search operations.
abstract class ProductRepository {
  /// Get a product by ID
  Future<ProductModel?> getProductById(String productId);

  /// Create a new product listing
  Future<ProductModel> createProduct(ProductModel product);

  /// Update an existing product
  Future<void> updateProduct(ProductModel product);

  /// Delete a product (owner only)
  Future<void> deleteProduct(String productId);

  /// Get products with filters, pagination
  Future<List<ProductModel>> getProducts({
    String? farmerId,
    ProductCategory? category,
    String? searchQuery,
    String? location,
    int limit = 20,
    String? lastDocumentId,
  });

  /// Stream products for real-time updates
  Stream<List<ProductModel>> watchProducts({
    String? farmerId,
    ProductCategory? category,
  });

  /// Get products by farmer ID
  Future<List<ProductModel>> getProductsByFarmer(String farmerId);

  /// Pause product listing
  Future<void> pauseProduct(String productId);

  /// Resume product listing
  Future<void> resumeProduct(String productId);
}
