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

class ReviewsRepository {
  final AppDatabase _database;

  ReviewsRepository(this._database);

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
