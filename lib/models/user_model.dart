import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String program;
  final String rank;
  final String role; // admin or student
  final DateTime createdAt;
  final double? monthlyRate;
  final DateTime? nextPaymentDate;
  final String? paymentMethod;
  final String? notes;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.program,
    required this.rank,
    this.role = 'student',
    required this.createdAt,
    this.monthlyRate,
    this.nextPaymentDate,
    this.paymentMethod,
    this.notes,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      program: data['program'] ?? '',
      rank: data['rank'] ?? 'White Belt',
      role: data['role'] ?? 'student',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      monthlyRate: (data['monthlyRate'] as num?)?.toDouble(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'program': program,
      'rank': rank,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (monthlyRate != null) 'monthlyRate': monthlyRate,
      if (nextPaymentDate != null) 'nextPaymentDate': Timestamp.fromDate(nextPaymentDate!),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
    };
  }

  String get fullName => '$firstName $lastName';
}