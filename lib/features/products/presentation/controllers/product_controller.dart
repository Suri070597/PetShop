import 'dart:async';

import '../../domain/product_model.dart';
import '../../domain/product_repository.dart';

/// Controller that mediates between the UI and [ProductRepository].
class ProductController {
  final ProductRepository _repository;

  /// All loaded products.
  List<Product> _products = [];
  List<Product> get products => List<Product>.unmodifiable(_products);

  /// Stream controller to notify listeners of state changes.
  final StreamController<List<Product>> _productsController =
      StreamController<List<Product>>.broadcast();
  Stream<List<Product>> get productsStream => _productsController.stream;

  /// Whether a load operation is in progress.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Last error message, if any.
  String? _error;
  String? get error => _error;

  ProductController(this._repository);

  /// ---------------------------------------------------------------------------
  /// READ
  /// ---------------------------------------------------------------------------

  /// Loads all products from the repository.
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    _notify();

    try {
      _products = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Returns a single product by its [id].
  Future<Product?> getById(String id) async {
    _error = null;
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  /// ---------------------------------------------------------------------------
  /// CREATE
  /// ---------------------------------------------------------------------------

  /// Creates a new product with the given fields.
  Future<bool> create({
    required int id,
    required String name,
    required String description,
    required double price,
    required String image,
    required String category,
    required double rating,
    required int categoryId,
  }) async {
    _error = null;
    try {
      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        image: image,
        category: category,
        rating: rating, 
        categoryId: categoryId,
      );
      await _repository.create(product);
      _products.add(product);
      _notify();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// ---------------------------------------------------------------------------
  /// UPDATE
  /// ---------------------------------------------------------------------------

  /// Updates an existing product.
  Future<bool> update(Product product) async {
    _error = null;
    try {
      await _repository.update(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      _notify();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// ---------------------------------------------------------------------------
  /// DELETE
  /// ---------------------------------------------------------------------------

  /// Deletes a product by its [id].
  Future<bool> delete(String id) async {
    _error = null;
    try {
      await _repository.delete(id);
      _products.removeWhere((p) => p.id.toString() == id);
      _notify();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// ---------------------------------------------------------------------------
  /// HELPERS
  /// ---------------------------------------------------------------------------

  void _notify() {
    _productsController.add(List<Product>.from(_products));
  }

  /// Disposes internal resources.
  void dispose() {
    _productsController.close();
  }
}