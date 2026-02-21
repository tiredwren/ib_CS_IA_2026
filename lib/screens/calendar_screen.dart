// filtering available classes based on rank/age/availability status
// admins can see all classes and manage them

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'class_manager.dart';
import 'add_event_screen.dart';

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

  List<DateTime> _expandDates(EventModel event) {
    const toWeekday = {
      "Monday": DateTime.monday,
      "Tuesday": DateTime.tuesday,
      "Wednesday": DateTime.wednesday,
      "Thursday": DateTime.thursday,
      "Friday": DateTime.friday,
      "Saturday": DateTime.saturday,
      "Sunday": DateTime.sunday
    };
    final now = DateTime.now();
    final stopAdding = now.add(const Duration(days: 90));
    final allDates = <DateTime>[];

    for (final day in event.daysOfWeek) {
      final weekday = toWeekday[day];
      int daysTo = (weekday! - now.weekday + 7) % 7;
      DateTime current = DateTime(now.year, now.month, now.day).add(Duration(days: daysTo));
      while (!current.isAfter(stopAdding)) {
        allDates.add(current);
        current = current.add(const Duration(days: 7));
      }
    }

    return allDates;
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    final isAdmin = authService.isAdmin;

    if (user == null) return;

    try {
      // load all events
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          //.where('startTime', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 30)))
          .get();

      Map<DateTime, List<EventModel>> eventsByDate = {};

      if (isAdmin) {
        // admins see all classes
        for (var doc in eventsSnapshot.docs) {
          final event = EventModel.fromFirestore(doc);

          for (final date in _expandDates(event)) {
            eventsByDate[date] ??= [];
            eventsByDate[date]!.add(event);
          }
        }

        print('Total dates mapped: ${eventsByDate.length}');
        eventsByDate.forEach((date, events) => print('$date: ${events.length} events'));
        eventsByDate.forEach((date, events) => print('$date: ${events.length} events'));

      } else {
        // students only see classes they're enrolled in or eligible for
        final enrollmentsSnapshot = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('userId', isEqualTo: user.uid)
            .where('isActive', isEqualTo: true)
            .get();

        final enrolledEventIds = enrollmentsSnapshot.docs
            .map((doc) => doc.data()['eventId'] as String)
            .toSet();

        for (var doc in eventsSnapshot.docs) {
          final event = EventModel.fromFirestore(doc);

          if (enrolledEventIds.contains(event.id) || event.isUserEligible(user.rank)) {
            for (final date in _expandDates(event)) {
              eventsByDate[date] ??= [];
              eventsByDate[date]!.add(event);
            }
          }
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
          SnackBar(content: Text('error loading events: $e')),
        );
      }
    }
  }

  // List<EventModel> _getEventsForDay(DateTime day) {
  //   final normDay = DateTime(day.year, day.month, day.day);
  //   return _events[normDay] ?? [];
  // }


  List<EventModel> _getEventsForDay(DateTime day) {
    // solves issue with calendar dots appearing only on four days
    // looks for year/month/day rather than time match
    return _events.entries
        .where((e) =>
    e.key.year == day.year &&
        e.key.month == day.month &&
        e.key.day == day.day)
        .expand((e) => e.value)
        .toList();
  }

  Future<void> _deleteEvent(EventModel event) async {
    try {
      // delete all enrollments for this event
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('eventId', isEqualTo: event.id)
          .get();

      for (var doc in enrollmentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // delete the event
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();

      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting class: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete class'),
        content: Text('Are you sure you want to delete "${event.name}"? this will remove all student enrollments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: TableCalendar(
              key: ValueKey(_events.length),
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

          // admin controls
          if (isAdmin) ...[
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFF0000).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Color(0xFFFF0000)),
                  const SizedBox(width: 8),
                  const Text(
                    'Admin Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF0000),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEventScreen(
                            selectedDate: _selectedDay ?? DateTime.now(),
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadEvents();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Class '),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5)
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

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
                return _buildEventCard(_selectedEvents[index], isAdmin);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isAdmin) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    return FutureBuilder<DocumentSnapshot?>(
      future: FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user?.uid)
          .where('eventId', isEqualTo: event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null),
      builder: (context, snapshot) {
        final isEnrolled = snapshot.hasData && snapshot.data != null;
        final enrollment = snapshot.hasData && snapshot.data != null
            ? EnrollmentModel.fromFirestore(snapshot.data!)
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            onTap: isAdmin
                ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassManagementScreen(event: event),
                ),
              );
              _loadEvents();
            }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.getDisplayName(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isEnrolled && !isAdmin)
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
                                ? 'waitlisted'
                                : 'enrolled',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isAdmin) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(event),
                          tooltip: 'Delete class',
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.room,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.military_tech, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Required: ${event.requiredRanks.join(", ")}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isAdmin) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.groups, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${event.currentEnrollment} / ${event.maxCapacity} students',
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
          ),
        );
      },
    );
  }
}