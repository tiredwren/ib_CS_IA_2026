import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // uniforms, sparring gear, gear bags, and weapons
  final List<String> sizes;
  final String? imageUrl;
  final bool inStock;
  final List<String> rankRequired;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.rankRequired,
    this.sizes = const [],
    this.imageUrl,
    this.inStock = true,
    required this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      sizes: List<String>.from(data['sizes'] ?? []),
      imageUrl: data['imageUrl'],
      inStock: data['inStock'] ?? true,
      rankRequired: data['rankRequired'] != null
          ? List<String>.from(data["rankRequired"])
          : [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'sizes': sizes,
      'imageUrl': imageUrl,
      'inStock': inStock,
      'rankRequired': rankRequired,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isAvailableForRank(String userRank) {
    if (rankRequired.isEmpty) return true;

    const rankOrder = [
      'White Belt',
      'Yellow Belt',
      'Green Belt',
      'Blue Belt',
      'Brown Belt',
      'Red Belt',
      'Black Belt',
    ];

    final userRankIndex = rankOrder.indexOf(userRank);
    final requiredRankIndex = rankOrder.indexOf(rankRequired[0]);

    if (userRankIndex == -1 || requiredRankIndex == -1) return false; // filter visibility based on user rank

    return rankRequired.contains(userRank);
  }
}