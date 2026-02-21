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
  final String room;
  final List<String> daysOfWeek;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

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
    this.room = 'Room A',
    this.daysOfWeek = const [],
    this.startHour = 0,
    this.endHour = 0,
    this.startMinute = 0,
    this.endMinute = 0
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
        id: doc.id,
        name: data['name'] ?? '',
        type: data['type'] ?? '',
        startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : DateTime.now(),
        endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : DateTime.now(),
        instructor: data['instructor'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        maxCapacity: data['maxCapacity'] ?? 0,
        currentEnrollment: data['currentEnrollment'] ?? 0,
        requiredRanks: List<String>.from(data['requiredRanks'] ?? []),
        description: data['description'],
        requirements: data['requirements'],
        room: data['room'] ?? 'Room A',
        daysOfWeek: List<String>.from(data['daysOfWeek'] ?? []),
        startHour: data["startHour"] ?? 9,
        startMinute: data["startMinute"] ?? 0,
        endHour: data["endHour"] ?? 10,
        endMinute: data["endMinute"] ?? 0
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
      'room': room,
      'daysOfWeek': daysOfWeek,
    };
  }

  bool isUserEligible(String userRank) {
    if (requiredRanks.isEmpty) return true;
    return requiredRanks.contains(userRank);
  }

  bool get isFull => currentEnrollment >= maxCapacity;

  // helper to put together display name like "M/W 3:00-4:30PM"
  String getDisplayName() {
    final dayAbbreviations = {
      'Monday': 'M',
      'Tuesday': 'T',
      'Wednesday': 'W',
      'Thursday': 'Th',
      'Friday': 'F',
      'Saturday': 'Sa',
      'Sunday': 'Su',
    };

    final days = daysOfWeek.map((day) => dayAbbreviations[day] ?? day).join('/');

    final startTimeStr = _formatTime(DateTime(0, 0, 0, startHour, startMinute));
    final endTimeStr = _formatTime(DateTime(0, 0, 0, endHour, endMinute));

    final timeRange = '$startTimeStr-$endTimeStr';

    if (name.isEmpty) {
      return '$days $timeRange';
    } else {
      return '$days $timeRange $name';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    if (time.minute == 0) {
      return '$hour$period';
    }
    return '$hour:$minute$period';
  }
}

class EnrollmentModel {
  final String id;
  final String userId;
  final String eventId;
  final String status; // 'enrolled', 'waitlisted', 'cancelled'
  final DateTime enrolledAt;
  final bool isPaid;
  final DateTime? removedAt; // new field - track when student was removed
  final bool isActive; // new field - false if student was removed

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.enrolledAt,
    this.isPaid = false,
    this.removedAt,
    this.isActive = true,
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
      removedAt: data['removedAt'] != null
          ? (data['removedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'isPaid': isPaid,
      'removedAt': removedAt != null ? Timestamp.fromDate(removedAt!) : null,
      'isActive': isActive,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // 'Uniforms', 'Weapons', 'Sparring Gear', 'Gear Bags'
  final List<String> sizes;
  final String? imageUrl;
  final bool inStock;
  final List<String> rankRequired; // eg. 'Black Belt', null means available to all
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

  // check if user's rank meets requirement
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

    if (userRankIndex == -1 || requiredRankIndex == -1) return false;

    return rankRequired.contains(userRank);
  }
}

class PurchaseModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double price;
  final String? size;
  final DateTime purchaseDate;
  final String status; // 'pending', 'completed', 'cancelled'
  final String paymentMethod; // placeholder for future payment integration

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

  String get monthYear {
    return '${purchaseDate.month}/${purchaseDate.year}';
  }
}