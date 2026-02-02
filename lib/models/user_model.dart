// model with all user-specific personalization (rank, age, etc.), affects what online booking/calendar events users can see

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String program;
  final String rank;
  final String role; // 'student' or 'admin'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.program,
    required this.rank,
    this.role = 'student',
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      program: data['program'] ?? '',
      rank: data['rank'] ?? 'White Belt',
      role: data['role'] ?? 'student',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    };
  }

  String get fullName => '$firstName $lastName';
}

class EventModel {
  final String id;
  final String name;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final String instructor;
  final double price;
  final int maxCapacity;
  final int currentEnrollment;
  final List<String> requiredRanks;
  final String? description;
  final String? requirements;

  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.instructor,
    required this.price,
    required this.maxCapacity,
    this.currentEnrollment = 0,
    this.requiredRanks = const [],
    this.description,
    this.requirements,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      instructor: data['instructor'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      maxCapacity: data['maxCapacity'] ?? 0,
      currentEnrollment: data['currentEnrollment'] ?? 0,
      requiredRanks: List<String>.from(data['requiredRanks'] ?? []),
      description: data['description'],
      requirements: data['requirements'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'instructor': instructor,
      'price': price,
      'maxCapacity': maxCapacity,
      'currentEnrollment': currentEnrollment,
      'requiredRanks': requiredRanks,
      'description': description,
      'requirements': requirements,
    };
  }

  bool isUserEligible(String userRank) {
    if (requiredRanks.isEmpty) return true;
    return requiredRanks.contains(userRank);
  }

  bool get isFull => currentEnrollment >= maxCapacity;
}

class EnrollmentModel {
  final String id;
  final String userId;
  final String eventId;
  final String status; // 'enrolled', 'waitlisted', 'cancelled'
  final DateTime enrolledAt;
  final bool isPaid;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.enrolledAt,
    this.isPaid = false,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EnrollmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      status: data['status'] ?? 'enrolled',
      enrolledAt: (data['enrolledAt'] as Timestamp).toDate(),
      isPaid: data['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'isPaid': isPaid,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> sizes;
  final String? imageUrl;
  final bool inStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.sizes = const [],
    this.imageUrl,
    this.inStock = true,
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
    };
  }
}