import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final String inst;
  final double price;
  final int maxCap;
  final int currEnrollment;
  final List<String> rankReq;
  final String? reqs;
  final String room;
  final List<String> days;
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
    required this.inst,
    required this.price,
    required this.maxCap,
    this.currEnrollment = 0,
    this.rankReq = const [],
    this.reqs,
    this.room = 'Room A',
    this.days = const [],
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
      inst: data['instructor'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      maxCap: data['maxCapacity'] ?? 0,
      currEnrollment: data['currentEnrollment'] ?? 0,
      rankReq: List<String>.from(data['requiredRanks'] ?? []),
      reqs: data['requirements'],
      room: data['room'] ?? 'Room A',
      days: List<String>.from(data['daysOfWeek'] ?? []),
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
      'instructor': inst,
      'price': price,
      'maxCapacity': maxCap,
      'currentEnrollment': currEnrollment,
      'requiredRanks': rankReq,
      'requirements': reqs,
      'room': room,
      'daysOfWeek': days,
    };
  }

  bool eligible(String userRank) {
    if (rankReq.isEmpty) return true;
    return rankReq.contains(userRank);
  }

  bool get isFull => currEnrollment >= maxCap;

  String getDispName() {
    final dayAbbreviations = {
      'Monday': 'M',
      'Tuesday': 'T',
      'Wednesday': 'W',
      'Thursday': 'Th',
      'Friday': 'F',
      'Saturday': 'Sa',
      'Sunday': 'Su',
    };

    final days = this.days.map((day) => dayAbbreviations[day] ?? day).join('/');
    final startTimeStr = _timeFormatting(DateTime(0, 0, 0, startHour, startMinute));
    final endTimeStr = _timeFormatting(DateTime(0, 0, 0, endHour, endMinute));
    final timeRange = '$startTimeStr-$endTimeStr';

    // name together for card formatting
    return name.isEmpty ? '$days $timeRange' : '$days $timeRange $name';
  }

  String _timeFormatting(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return time.minute == 0 ? '$hour$period' : '$hour:$minute$period';
  }
}