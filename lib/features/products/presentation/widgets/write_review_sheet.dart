import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../auth/providers/auth_controller.dart';
import '../provider/product_provider.dart';
import '../screens/product_detail_screen.dart';
import '../../../orders/presentation/providers/order_provider.dart';

/// Open modal bottom sheet to write a review for a specific product.
Future<void> showWriteReviewBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  required int productId,
  required String productName,
  VoidCallback? onReviewSubmitted,
}) async {
  final authUser = ref.read(authControllerProvider).valueOrNull;
  final prefUserId = ref.read(preferencesServiceProvider).currentUserId;
  final fbUser = ref.read(authRepositoryProvider).firebaseUser;

  final userId = authUser?.id ?? prefUserId ?? fbUser?.uid;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vui lòng đăng nhập để viết đánh giá.'),
        action: SnackBarAction(
          label: 'Đăng nhập',
          textColor: AppColors.honey,
          onPressed: () => Navigator.pushNamed(context, RouteNames.login),
        ),
      ),
    );
    return;
  }

  int selectedRating = 5;
  final commentController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              22,
              22,
              MediaQuery.of(context).viewInsets.bottom + 34,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá $productName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chất lượng sản phẩm:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    final starRating = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => selectedRating = starRating),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          starRating <= selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.honey,
                          size: 38,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Nhận xét của bạn:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhập bình luận tại đây...',
                    hintStyle: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                    ),
                    fillColor: AppColors.mist,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final comment = commentController.text;
                      if (comment.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập bình luận'),
                          ),
                        );
                        return;
                      }

                      try {
                        await ref.read(reviewsRepositoryProvider).addReview(
                              userId: userId,
                              productId: productId,
                              rating: selectedRating,
                              comment: comment,
                            );

                        ref.invalidate(productReviewsStreamProvider(productId));
                        ref.invalidate(productProvider);
                        ref.invalidate(reviewEligibilityProvider);
                        ref.invalidate(orderIsFullyReviewedProvider);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã gửi đánh giá thành công!'),
                            ),
                          );
                        }

                        onReviewSubmitted?.call();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gửi đánh giá lỗi: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Gửi đánh giá',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
