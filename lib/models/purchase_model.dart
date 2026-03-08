import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String userId;
  final String prodId;
  final String prodName;
  final double price;
  final String? size;
  final DateTime date;
  final String status; // 'pending', 'completed', 'cancelled'
  final String payMeth;

  PurchaseModel({
    required this.id,
    required this.userId,
    required this.prodId,
    required this.prodName,
    required this.price,
    this.size,
    required this.date,
    this.status = 'pending',
    this.payMeth = 'pending',
  });

  factory PurchaseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PurchaseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      prodId: data['productId'] ?? '',
      prodName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      size: data['size'],
      date: (data['purchaseDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      payMeth: data['paymentMethod'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': prodId,
      'productName': prodName,
      'price': price,
      'size': size,
      'purchaseDate': Timestamp.fromDate(date),
      'status': status,
      'paymentMethod': payMeth,
    };
  }

  String get monthYear => '${date.month}/${date.year}';
}