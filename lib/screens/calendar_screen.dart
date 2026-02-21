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
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };
    final now = DateTime.now();
    final stop = now.add(const Duration(days: 90));
    final dates = <DateTime>[];

    for (final day in event.daysOfWeek) {
      final weekday = toWeekday[day];
      int daysTo = (weekday! - now.weekday + 7) % 7;
      DateTime current = DateTime(now.year, now.month, now.day).add(Duration(days: daysTo));
      while (!current.isAfter(stop)) {
        dates.add(current);
        current = current.add(const Duration(days: 7));
      }
    }
    return dates;
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    final isAdmin = authService.isAdmin;

    if (user == null) return;

    try {
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .get();

      Map<DateTime, List<EventModel>> eventsByDate = {};

      if (isAdmin) {
        for (var doc in eventsSnapshot.docs) {
          final event = EventModel.fromFirestore(doc);
          for (final date in _expandDates(event)) {
            eventsByDate[date] ??= [];
            eventsByDate[date]!.add(event);
          }
        }
      } else {
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
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    // match by date only, not time, to fix dots appearing on only a few days
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
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('eventId', isEqualTo: event.id)
          .get();

      for (var doc in enrollmentsSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();

      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted')),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete "${event.name}"?',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'This will remove all student enrollments for this class.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteEvent(event);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCC0000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // calendar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  color: const Color(0xFFCC0000).withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFCC0000),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFCC0000),
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
          const SizedBox(height: 10,),
          const Divider(height: 1),

          // create class button
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventScreen(
                          selectedDate: _selectedDay ?? DateTime.now(),
                        ),
                      ),
                    );
                    if (result == true) _loadEvents();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create class'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCC0000),
                    overlayColor: Colors.transparent,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          // event list
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
              child: Text(
                'No classes on this day',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _selectedEvents.length,
              itemBuilder: (context, i) =>
                  _buildEventCard(_selectedEvents[i], isAdmin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isAdmin) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    final timeStr =
        '${DateFormat.jm().format(event.startTime)} – ${DateFormat.jm().format(event.endTime)}';

    return FutureBuilder<DocumentSnapshot?>(
      future: FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user?.uid)
          .where('eventId', isEqualTo: event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get()
          .then((s) => s.docs.isNotEmpty ? s.docs.first : null),
      builder: (context, snapshot) {
        final enrollment = snapshot.hasData && snapshot.data != null
            ? EnrollmentModel.fromFirestore(snapshot.data!)
            : null;
        final isWaitlisted = enrollment?.status == 'waitlisted';
        final isEnrolled = enrollment != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // time column
                  SizedBox(
                    width: 68,
                    child: Text(
                      timeStr.replaceFirst(' ', '\n'),
                      style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.getDisplayName(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.instructor} · ${event.room}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                        if (event.requiredRanks.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            event.requiredRanks.join(', '),
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (isAdmin) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${event.currentEnrollment}/${event.maxCapacity} students',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // status badge or admin controls
                  if (isEnrolled && !isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isWaitlisted ? Colors.orange.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isWaitlisted ? Colors.orange.shade200 : Colors.green.shade200,
                        ),
                      ),
                      child: Text(
                        isWaitlisted ? 'Waitlist' : 'Enrolled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isWaitlisted ? Colors.orange.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),

                  if (isAdmin)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showDeleteConfirmation(event),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: Icon(Icons.delete_outline, size: 18, color: Colors.grey[350]),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: Colors.grey[350]),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}