import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final String? size;
  final DateTime purchaseDate;
  final String status; // 'pending', 'completed', 'cancelled'
  final String paymentMethod;

  PurchaseModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    this.size,
    required this.purchaseDate,
    this.status = 'pending',
    this.paymentMethod = 'pending',
  });

  factory PurchaseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PurchaseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      size: data['size'],
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'size': size,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }

  String get monthYear => '${purchaseDate.month}/${purchaseDate.year}';
}