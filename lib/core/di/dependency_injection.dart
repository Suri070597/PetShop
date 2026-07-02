import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/cloudinary/cloudinary_service.dart';
import '../../data/datasources/drift/app_database.dart';
import '../../data/datasources/firebase/auth_service.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../data/repositories/vouchers_repository.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/repositories/reviews_repository.dart';
import '../../features/cart/data/cart_repository.dart';
import '../../features/products/data/product_repository_impl.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences must be overridden.'),
);

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  final service = CloudinaryService();
  ref.onDispose(service.close);
  return service;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(firebaseAuthServiceProvider),
    database: ref.watch(appDatabaseProvider),
    preferences: ref.watch(preferencesServiceProvider),
  );
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(appDatabaseProvider));
});

final productRepositoryImplProvider = Provider<ProductRepositoryImpl>((ref) {
  return ProductRepositoryImpl(ref.watch(appDatabaseProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(appDatabaseProvider));
});

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(appDatabaseProvider));
});

final vouchersRepositoryProvider = Provider<VouchersRepository>((ref) {
  return VouchersRepository(ref.watch(appDatabaseProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(appDatabaseProvider));
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(appDatabaseProvider));
});

