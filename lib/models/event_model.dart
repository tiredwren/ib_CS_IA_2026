import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? requirements;
  final String room;
  final List<String> daysOfWeek;
  // separated for name
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
    this.requirements,
    this.room = 'Room A',
    this.daysOfWeek = const [],
    this.startHour = 0,
    this.endHour = 0,
    this.startMinute = 0,
    this.endMinute = 0,
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
      requirements: data['requirements'],
      room: data['room'] ?? 'Room A',
      daysOfWeek: List<String>.from(data['daysOfWeek'] ?? []),
      startHour: data["startHour"] ?? 9,
      startMinute: data["startMinute"] ?? 0,
      endHour: data["endHour"] ?? 10,
      endMinute: data["endMinute"] ?? 0,
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

    // name together for card formatting
    return name.isEmpty ? '$days $timeRange' : '$days $timeRange $name';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return time.minute == 0 ? '$hour$period' : '$hour:$minute$period';
  }
}