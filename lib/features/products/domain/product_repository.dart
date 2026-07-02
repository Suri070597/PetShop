import 'dart:async';

import 'product_model.dart';

/// Abstract repository defining CRUD operations for [ProductModel].
abstract class ProductRepository {
	/// Returns all products.
	Future<List<Product>> getAll();

	/// Returns a product by its [id] or null if not found.
	Future<Product?> getById(String id);

	/// Creates a new [product].
	Future<void> create(Product product);

	/// Updates an existing [product].
	Future<void> update(Product product);

	/// Deletes a product identified by [id].
	Future<void> delete(String id);

	/// Searches products by a text query, typically on the product name.
	Future<List<Product>> search(String query);

	/// Filters products using a custom predicate.
	Future<List<Product>> filter(bool Function(Product) predicate);

	/// Returns products sorted according to the provided comparator.
	Future<List<Product>> sort(Comparator<Product> comparator);
}

/// Simple in‑memory implementation of [ProductRepository].
/// This is useful for testing or prototyping.
class InMemoryProductRepository implements ProductRepository {
	final List<Product> _products = [];

	@override
	Future<List<Product>> getAll() async {
		// Return a copy to prevent external mutation.
		return List<Product>.from(_products);
	}

	@override
	Future<Product?> getById(String id) async {
		final index = _products.indexWhere((p) => p.id.toString() == id);
		return index != -1 ? _products[index] : null;
	}

	@override
	Future<void> create(Product product) async {
		// Ensure no duplicate IDs.
		if (_products.any((p) => p.id == product.id)) {
			throw ArgumentError('Product with id ${product.id} already exists');
		}
		_products.add(product);
	}

	@override
	Future<void> update(Product product) async {
		final index = _products.indexWhere((p) => p.id == product.id);
		if (index == -1) {
			throw ArgumentError('Product with id ${product.id} not found');
		}
		_products[index] = product;
	}

	@override
	Future<void> delete(String id) async {
		_products.removeWhere((p) => p.id.toString() == id);
	}

	@override
	Future<List<Product>> search(String query) async {
		final lower = query.toLowerCase();
		// Assuming Product has a `name` field. Adjust if different.
		return _products
			.where((p) => p.name.toLowerCase().contains(lower))
			.toList();
	}

	@override
	Future<List<Product>> filter(bool Function(Product) predicate) async {
		return _products.where(predicate).toList();
	}

	@override
	Future<List<Product>> sort(Comparator<Product> comparator) async {
		final sorted = List<Product>.from(_products);
		sorted.sort(comparator);
		return sorted;
	}
}
