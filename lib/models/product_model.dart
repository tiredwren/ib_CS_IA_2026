import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String desc;
  final double price;
  final String category; // uniforms, sparring gear, gear bags, and weapons
  final List<String> sizes;
  final String? imageUrl;
  final bool inStock;
  final List<String> rankReq;
  final DateTime created;

  ProductModel({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.category,
    required this.rankReq,
    this.sizes = const [],
    this.imageUrl,
    this.inStock = true,
    required this.created,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      desc: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      sizes: List<String>.from(data['sizes'] ?? []),
      imageUrl: data['imageUrl'],
      inStock: data['inStock'] ?? true,
      rankReq: data['rankRequired'] != null
          ? List<String>.from(data["rankRequired"])
          : [],
      created: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': desc,
      'price': price,
      'category': category,
      'sizes': sizes,
      'imageUrl': imageUrl,
      'inStock': inStock,
      'rankRequired': rankReq,
      'createdAt': Timestamp.fromDate(created),
    };
  }

  bool rankAvail(String userRank) {
    if (rankReq.isEmpty) return true;

    const rankOrder = [
      'White Belt',
      'Yellow Belt',
      'Green Belt',
      'Blue Belt',
      'Brown Belt',
      'Red Belt',
      'Black Belt',
    ];

    final rankIdx = rankOrder.indexOf(userRank);
    final requiredRankIndex = rankOrder.indexOf(rankReq[0]);

    if (rankIdx == -1 || requiredRankIndex == -1) return false; // filter visibility based on user rank

    return rankReq.contains(userRank);
  }
}