import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String userId;
  final String eventId;
  final String status; // enrolled, waitlisted, or cancelled
  final DateTime enrolled;
  final bool paid;
  final DateTime? removedAt;
  final bool active;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.enrolled,
    this.paid = false,
    this.removedAt,
    this.active = true,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EnrollmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      status: data['status'] ?? 'enrolled',
      enrolled: (data['enrolledAt'] as Timestamp).toDate(),
      paid: data['isPaid'] ?? false,
      removedAt: data['removedAt'] != null // only filed if class deleted by admin
          ? (data['removedAt'] as Timestamp).toDate()
          : null,
      active: data['isActive'] ?? true, // false if removed by admin, else true
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status,
      'enrolledAt': Timestamp.fromDate(enrolled),
      'isPaid': paid,
      'removedAt': removedAt != null ? Timestamp.fromDate(removedAt!) : null,
      'isActive': active,
    };
  }
}