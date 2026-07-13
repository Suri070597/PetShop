import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/data/datasources/drift/app_database.dart';
import 'package:pet_shop/data/repositories/wishlist_repository.dart';
import 'package:pet_shop/data/repositories/vouchers_repository.dart';
import 'package:pet_shop/data/repositories/reviews_repository.dart';
import 'package:pet_shop/core/errors/exceptions.dart';

void main() {
  late AppDatabase db;
  late WishlistRepository wishlistRepo;
  late VouchersRepository vouchersRepo;
  late ReviewsRepository reviewsRepo;

  const testUserId = 'test_user_123';
  const testProductId = 1;

  setUp(() async {
    // Initialize in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
    wishlistRepo = WishlistRepository(db);
    vouchersRepo = VouchersRepository(db);
    reviewsRepo = ReviewsRepository(db);

    // Seed test data
    await db.seedCatalog();
    
    // Seed test user
    await db.into(db.localUsers).insertOnConflictUpdate(
          LocalUsersCompanion.insert(
            id: testUserId,
            fullName: 'Test User',
            email: 'test@example.com',
            emailVerified: const Value(true),
            status: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Wishlist Repository Tests', () {
    test('Verify product is not favorite initially', () async {
      final isFav = await wishlistRepo.isFavorite(testUserId, testProductId);
      expect(isFav, isFalse);
    });

    test('Add to wishlist and verify isFavorite', () async {
      await wishlistRepo.toggleFavorite(testUserId, testProductId);
      final isFav = await wishlistRepo.isFavorite(testUserId, testProductId);
      expect(isFav, isTrue);

      final wishlistList = await wishlistRepo.watchWishlist(testUserId).first;
      expect(wishlistList.length, 1);
      expect(wishlistList.first.id, testProductId);
    });

    test('Remove from wishlist when toggled twice', () async {
      // Toggle 1: Add
      await wishlistRepo.toggleFavorite(testUserId, testProductId);
      // Toggle 2: Remove
      await wishlistRepo.toggleFavorite(testUserId, testProductId);

      final isFav = await wishlistRepo.isFavorite(testUserId, testProductId);
      expect(isFav, isFalse);

      final wishlistList = await wishlistRepo.watchWishlist(testUserId).first;
      expect(wishlistList, isEmpty);
    });
  });

  group('Reviews Repository Tests', () {
    test('Add review and verify averageRating and reviewCount updates', () async {
      // Product 1 initially has 2 reviews from seeder (average rating: 4.5)
      var productBefore = await (db.select(db.products)
            ..where((t) => t.productId.equals(testProductId)))
          .getSingle();
      expect(productBefore.reviewCount, 2);
      expect(productBefore.averageRating, 4.5);

      // Add a 5-star review
      await reviewsRepo.addReview(
        userId: testUserId,
        productId: testProductId,
        rating: 5,
        comment: 'Tuyệt vời, 5 sao!',
      );

      // Verify product ratings updated (2 reviews of 5 + 4 = 9 total; new review is 5. New average = (9+5)/3 = 4.67)
      var productAfter = await (db.select(db.products)
            ..where((t) => t.productId.equals(testProductId)))
          .getSingle();
      expect(productAfter.reviewCount, 3);
      expect(productAfter.averageRating, closeTo(4.66, 0.01));

      // Verify review content streamed correctly
      final reviewsList = await reviewsRepo.watchReviewsForProduct(testProductId).first;
      expect(reviewsList.length, 3);
      expect(reviewsList.first.reviewerName, 'Test User');
      expect(reviewsList.first.comment, 'Tuyệt vời, 5 sao!');
      expect(reviewsList.first.rating, 5);
    });
  });

  group('Vouchers Repository Tests', () {
    test('Get all active vouchers', () async {
      final list = await vouchersRepo.getVouchers();
      // Seeder inserts 3 active vouchers
      expect(list.length, 3);
      expect(list.any((v) => v.code == 'PETJOYNEW'), isTrue);
    });

    test('Apply valid voucher successfully', () async {
      // PETJOYNEW has minOrderValue = 20.0
      final voucher = await vouchersRepo.applyVoucher('PETJOYNEW', 25.0);
      expect(voucher.code, 'PETJOYNEW');
      expect(voucher.discountPercent, 15);
    });

    test('Apply voucher throws exception when order value too low', () async {
      // PETJOYNEW requires minimum order value of 20.0
      expect(
        () => vouchersRepo.applyVoucher('PETJOYNEW', 15.0),
        throwsA(isA<AppException>().having((e) => e.message, 'message', contains('Đơn hàng chưa đạt giá trị tối thiểu'))),
      );
    });

    test('Apply invalid voucher code throws exception', () async {
      expect(
        () => vouchersRepo.applyVoucher('INVALID_CODE', 100.0),
        throwsA(isA<AppException>().having((e) => e.message, 'message', contains('Mã giảm giá không tồn tại'))),
      );
    });
  });
}
