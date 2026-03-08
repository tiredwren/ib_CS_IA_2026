import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstN;
  final String lastN;
  final String program;
  final String rank;
  final String role; // admin or student
  final DateTime created;
  final double? monthRate;
  final DateTime? nextPay;
  final String? payMeth;
  final String? notes;
  final String age; // youth or adult

  UserModel({
    required this.uid,
    required this.email,
    required this.firstN,
    required this.lastN,
    required this.program,
    required this.rank,
    this.role = 'student',
    required this.created,
    this.monthRate,
    this.nextPay,
    this.payMeth,
    this.notes,
    this.age = 'adult',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstN: data['firstName'] ?? '',
      lastN: data['lastName'] ?? '',
      program: data['program'] ?? '',
      rank: data['rank'] ?? 'White Belt',
      role: data['role'] ?? 'student',
      created:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      monthRate: (data['monthlyRate'] as num?)?.toDouble(),
      nextPay: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      payMeth: data['paymentMethod'] as String?,
      notes: data['notes'] as String?,
      age: data['ageGroup'] ?? 'adult',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstN,
      'lastName': lastN,
      'program': program,
      'rank': rank,
      'role': role,
      'createdAt': Timestamp.fromDate(created),
      'ageGroup': age,
      if (monthRate != null) 'monthlyRate': monthRate,
      if (nextPay != null) 'nextPaymentDate': Timestamp.fromDate(nextPay!),
      if (payMeth != null) 'paymentMethod': payMeth,
      if (notes != null) 'notes': notes,
    };
  }

  String get fullName => '$firstN $lastN';
}