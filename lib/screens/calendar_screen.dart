// CLIENT-REQUESTED filtering available classes based on rank/age/availability status

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<EventModel>> _events = {};
  List<EventModel> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user == null) return;

    try {
      // load all events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('startTime', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 30)))
          .get();

      // load events user is enrolled in
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .get();

      final enrolledEventIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['eventId'] as String)
          .toSet();

      Map<DateTime, List<EventModel>> eventsByDate = {};

      for (var doc in eventsSnapshot.docs) {
        final event = EventModel.fromFirestore(doc);

        // only show events user is enrolled in or events they're eligible for
        if (enrolledEventIds.contains(event.id) || event.isUserEligible(user.rank)) {
          final date = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );

          if (eventsByDate[date] == null) {
            eventsByDate[date] = [];
          }
          eventsByDate[date]!.add(event);
        }
      }

      setState(() {
        _events = eventsByDate;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedEvents = _getEventsForDay(selectedDay);
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFFF0000),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFFF0000),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No classes scheduled',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                return _buildEventCard(_selectedEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user?.uid)
          .where('eventId', isEqualTo: event.id)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null as DocumentSnapshot),
      builder: (context, snapshot) {
        final isEnrolled = snapshot.hasData && snapshot.data != null;
        final enrollment = snapshot.hasData && snapshot.data != null
            ? EnrollmentModel.fromFirestore(snapshot.data!)
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isEnrolled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: enrollment?.status == 'waitlisted'
                              ? Colors.orange
                              : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          enrollment?.status == 'waitlisted'
                              ? 'Waitlisted'
                              : 'Enrolled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      event.instructor,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (event.requiredRanks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.military_tech, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Required: ${event.requiredRanks.join(", ")}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.price > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '\$${event.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}