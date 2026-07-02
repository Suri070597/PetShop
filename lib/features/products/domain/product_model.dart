
/// Domain model for a product.
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final double rating;
  final int categoryId; //dữ liệu categoryId được lấy từ API, là int, nhưng trong CategoryHelper sử dụng String, nên cần convert sang String khi so sánh.

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.rating,
    required this.categoryId, //dữ liệu categoryId được lấy từ API, là int, nhưng trong CategoryHelper sử dụng String, nên cần convert sang String khi so sánh. 
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      image: json['image'],
      category: json['category'],
      rating: json['rating'].toDouble(), 
      categoryId: json['category_id'] ?? json['categoryId'] ?? 1, //dữ liệu categoryId được lấy từ API, là int, nhưng trong CategoryHelper sử dụng String, nên cần convert sang String khi so sánh.
    );
  }
}
