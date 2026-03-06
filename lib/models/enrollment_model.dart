import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String userId;
  final String eventId;
  final String status; // enrolled, waitlisted, or cancelled
  final DateTime enrolledAt;
  final bool isPaid;
  final DateTime? removedAt;
  final bool isActive;

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
      removedAt: data['removedAt'] != null // only filed if class deleted by admin
          ? (data['removedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true, // false if removed by admin, else true
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