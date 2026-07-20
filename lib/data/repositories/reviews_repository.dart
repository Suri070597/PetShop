import 'package:drift/drift.dart';
import '../datasources/drift/app_database.dart';

class ReviewDisplay {
  final int reviewId;
  final String reviewerName;
  final String? avatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewDisplay({
    required this.reviewId,
    required this.reviewerName,
    this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

enum ReviewEligibilityStatus {
  canReview,
  notPurchased,
  alreadyReviewedAllPurchases,
}

class ReviewEligibility {
  final ReviewEligibilityStatus status;
  final int deliveredCount;
  final int reviewCount;

  ReviewEligibility({
    required this.status,
    required this.deliveredCount,
    required this.reviewCount,
  });
}

class ReviewsRepository {
  final AppDatabase _database;

  ReviewsRepository(this._database);

  /// Check if the user is eligible to review a product.
  /// A user can write a review if:
  /// - They have bought the product in at least one Delivered order.
  /// - Their total reviews for this product is less than their total Delivered purchases.
  Future<ReviewEligibility> checkReviewEligibility(
    String userId,
    int productId,
  ) async {
    // 1. Query Delivered orders containing this product
    final query = _database.select(_database.orders).join([
      innerJoin(
        _database.orderDetails,
        _database.orderDetails.orderId.equalsExp(_database.orders.orderId),
      )
    ])
      ..where(_database.orders.userId.equals(userId))
      ..where(_database.orderDetails.productId.equals(productId))
      ..where(_database.orders.orderStatus.equals('Delivered'));

    final orderRows = await query.get();
    final deliveredCount = orderRows.length;

    // 2. Query total reviews already submitted by this user for this product
    final reviewRows = await (_database.select(_database.reviews)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.productId.equals(productId)))
        .get();
    final reviewCount = reviewRows.length;

    if (deliveredCount == 0) {
      return ReviewEligibility(
        status: ReviewEligibilityStatus.notPurchased,
        deliveredCount: 0,
        reviewCount: reviewCount,
      );
    }

    if (reviewCount >= deliveredCount) {
      return ReviewEligibility(
        status: ReviewEligibilityStatus.alreadyReviewedAllPurchases,
        deliveredCount: deliveredCount,
        reviewCount: reviewCount,
      );
    }

    return ReviewEligibility(
      status: ReviewEligibilityStatus.canReview,
      deliveredCount: deliveredCount,
      reviewCount: reviewCount,
    );
  }

  /// Watch reviews for a product joined with the reviewer's user profile.
  Stream<List<ReviewDisplay>> watchReviewsForProduct(int productId) {
    final query = _database.select(_database.reviews).join([
      innerJoin(
        _database.localUsers,
        _database.localUsers.id.equalsExp(_database.reviews.userId),
      )
    ])
      ..where(_database.reviews.productId.equals(productId))
      ..orderBy([OrderingTerm(expression: _database.reviews.createdAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final review = row.readTable(_database.reviews);
        final user = row.readTable(_database.localUsers);
        return ReviewDisplay(
          reviewId: review.reviewId,
          reviewerName: user.fullName,
          avatarUrl: user.avatar,
          rating: review.rating,
          comment: review.comment ?? '',
          createdAt: review.createdAt,
        );
      }).toList();
    });
  }

  /// Add a new review and recalculate the product rating average and count.
  Future<void> addReview({
    required String userId,
    required int productId,
    required int rating,
    required String comment,
  }) async {
    // 1. Insert the review
    await _database.into(_database.reviews).insert(
          ReviewsCompanion.insert(
            userId: userId,
            productId: productId,
            rating: rating,
            comment: Value(comment.trim()),
            createdAt: Value(DateTime.now()),
          ),
        );

    // 2. Query all reviews for this product to recalculate rating average
    final reviewsList = await (_database.select(_database.reviews)
          ..where((t) => t.productId.equals(productId)))
        .get();

    final count = reviewsList.length;
    final totalRating = reviewsList.fold<int>(0, (sum, r) => sum + r.rating);
    final average = count > 0 ? (totalRating / count) : 0.0;

    // 3. Update the average rating and review count on the Product
    await (_database.update(_database.products)
          ..where((t) => t.productId.equals(productId)))
        .write(
      ProductsCompanion(
        averageRating: Value(average),
        reviewCount: Value(count),
      ),
    );
  }
}
