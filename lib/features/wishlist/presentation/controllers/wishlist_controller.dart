import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/repositories/wishlist_repository.dart';
import '../../../../features/products/domain/product_model.dart';
import '../../../../features/profile/screens/profile_screen.dart';
import '../../../auth/providers/auth_controller.dart';

/// Provider for the current logged-in user ID.
final currentUserIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authControllerProvider).valueOrNull;
  if (authUser != null) {
    return authUser.emailVerified ? authUser.id : null;
  }
  final fbUser = ref.watch(firebaseAuthServiceProvider).currentUser;
  final prefUserId = ref.watch(preferencesServiceProvider).currentUserId;
  return fbUser?.uid ?? prefUserId;
});

/// Stream provider that watches the current user's wishlist products.
final wishlistStreamProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(wishlistRepositoryProvider).watchWishlist(userId);
});

/// Future provider to check if a specific product is favorited by the current user.
final isProductFavoriteProvider = FutureProvider.family.autoDispose<bool, int>((ref, productId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return ref.watch(wishlistRepositoryProvider).isFavorite(userId, productId);
});


/// Controller to handle wishlist actions.
class WishlistController {
  final WishlistRepository _repository;
  final Ref _ref;

  WishlistController(this._repository, this._ref);

  /// Toggle the favorite status of a product.
  Future<bool> toggleFavorite(BuildContext context, int productId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để lưu sản phẩm yêu thích.'),
          action: SnackBarAction(
            label: 'Đăng nhập',
            textColor: AppColors.honey,
            onPressed: () => Navigator.pushNamed(context, RouteNames.login),
          ),
        ),
      );
      return false;
    }
    await _repository.toggleFavorite(userId, productId);
    _ref.invalidate(isProductFavoriteProvider(productId));
    _ref.invalidate(wishlistStreamProvider);
    _ref.invalidate(profileSummaryProvider);
    return true;
  }
}

final wishlistControllerProvider = Provider<WishlistController>((ref) {
  return WishlistController(ref.watch(wishlistRepositoryProvider), ref);
});
