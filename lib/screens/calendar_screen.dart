import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'class_manager.dart';
import 'add_event_screen.dart';
import '../models/event_model.dart';
import '../models/enrollment_model.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  CalendarFormat _fmt = CalendarFormat.month;
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<EventModel>> _events = {};
  List<EventModel> _dayEvents = [];

  // stream subscription so widget can cancel it on dispose
  Stream<QuerySnapshot>? _eventsStream;
  Stream<QuerySnapshot>? _enrollmentsStream;

  @override
  void initState() {
    super.initState();
    _selected = _focused;
    _setupStreams();
  }

  void _setupStreams() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currUser;
    if (user == null) return;

    // listen to events collection in real time
    _eventsStream =
        FirebaseFirestore.instance.collection('events').snapshots();

    if (!auth.isAdmin) {
      // also listen to this student's enrollments in real time
      _enrollmentsStream = FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .snapshots();
    }
  }

  // expand recurring event into individual calendar dates (90 day window)
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

    for (final day in event.days) {
      final weekday = toWeekday[day];
      if (weekday == null) continue;
      // modulus ensures daysTo is always positive (future date)
      int daysTo = (weekday - now.weekday + 7) % 7;
      DateTime cur = DateTime(now.year, now.month, now.day)
          .add(Duration(days: daysTo));
      while (!cur.isAfter(stop)) {
        dates.add(cur);
        cur = cur.add(const Duration(days: 7));
      }
    }
    return dates;
  }

  // rebuild event map from fresh snapshot
  Map<DateTime, List<EventModel>> _buildEventMap(
      List<EventModel> allEvents,
      Set<String> enrIds,
      UserModel user,
      bool isAdmin,
      ) {
    final Map<DateTime, List<EventModel>> byDate = {};

    for (final event in allEvents) {
      // admins see all events
      // students see eligible + already enrolled
      final show = isAdmin ||
          event.eligible(user.rank, user.age) ||
          enrIds.contains(event.id);

      if (show) {
        for (final date in _expandDates(event)) {
          byDate[date] ??= [];
          byDate[date]!.add(event);
        }
      }
    }
    return byDate;
  }

  List<EventModel> _getEventsForDay(DateTime day) {
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
      // remove all enrollments for this event first
      final enrSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('eventId', isEqualTo: event.id)
          .get();

      for (final doc in enrSnap.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();

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

  void _confirmDelete(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete "${event.name}"?',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'This will remove all student enrollments for this class.',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.black87)),
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
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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

  void _showClassDetail(EventModel event, EnrollmentModel? enr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentClassSheet(
        event: event,
        enrollment: enr,
        onRequest: () {
          Navigator.pop(ctx);
          _requestEnrollment(event);
        },
        onCancel: () {
          Navigator.pop(ctx);
          _cancelRequest(event, enr!);
        },
      ),
    );
  }

  Future<void> _requestEnrollment(EventModel event) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currUser;
    if (user == null) return;

    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .get();
      final curr =
          (eventDoc.data()?['currentEnrollment'] as int?) ?? 0;
      final full = curr >= event.maxCap;

      int waitPos = 0;
      if (full) {
        final waitSnap = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('eventId', isEqualTo: event.id)
            .where('status', isEqualTo: 'waitlisted')
            .get();
        waitPos = waitSnap.docs.length;
      }

      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': user.uid,
        'eventId': event.id,
        'status': full ? 'waitlisted' : 'pending',
        'enrolledAt': Timestamp.now(),
        'isActive': true,
        'isPaid': false,
        'waitlistPosition': full ? waitPos : 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(full
                ? 'Added to waitlist; you\'re number ${waitPos + 1}'
                : 'Request sent, waiting for admin confirmation'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cancelRequest(
      EventModel event, EnrollmentModel enr) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: enr.userId)
          .where('eventId', isEqualTo: event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      final cancelPos =
          doc.data()['waitlistPosition'] as int? ?? 0;
      final wasWait = enr.status == 'waitlisted';

      await doc.reference.update({'isActive': false});

      if (wasWait) {
        final behind = await FirebaseFirestore.instance
            .collection('enrollments')
            .where('eventId', isEqualTo: event.id)
            .where('status', isEqualTo: 'waitlisted')
            .where('isActive', isEqualTo: true)
            .get();

        for (final d in behind.docs) {
          final pos = d.data()['waitlistPosition'] as int? ?? 0;
          if (pos > cancelPos) {
            await d.reference
                .update({'waitlistPosition': pos - 1});
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currUser;
    final isAdmin = auth.isAdmin;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    // use nested StreamBuilders so both events and enrollments
    // trigger a rebuild when either changes in Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: _eventsStream,
      builder: (context, eventsSnap) {
        if (eventsSnap.connectionState == ConnectionState.waiting &&
            _events.isEmpty) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // rebuild event map whenever either stream emits
        if (eventsSnap.hasData) {
          final allEvents = eventsSnap.data!.docs
              .map((d) => EventModel.fromFirestore(d))
              .toList();

          if (isAdmin) {
            final newMap =
            _buildEventMap(allEvents, {}, user, true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _events = newMap;
                  _dayEvents = _getEventsForDay(_selected!);
                });
              }
            });
          }
        }

        if (isAdmin) {
          return _buildScaffold(isAdmin);
        }

        // student view: also stream enrollments
        return StreamBuilder<QuerySnapshot>(
          stream: _enrollmentsStream,
          builder: (context, enrSnap) {
            if (enrSnap.hasData && eventsSnap.hasData) {
              final enrIds = enrSnap.data!.docs
                  .map((d) =>
              (d.data() as Map<String, dynamic>)['eventId']
              as String)
                  .toSet();

              final allEvents = eventsSnap.data!.docs
                  .map((d) => EventModel.fromFirestore(d))
                  .toList();

              final newMap =
              _buildEventMap(allEvents, enrIds, user, false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _events = newMap;
                    _dayEvents = _getEventsForDay(_selected!);
                  });
                }
              });
            }
            return _buildScaffold(isAdmin);
          },
        );
      },
    );
  }

  Widget _buildScaffold(bool isAdmin) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text('Calendar',
            style:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventScreen(
                          selectedDate: _selected ?? DateTime.now(),
                        ),
                      ),
                    );
                    // no manual reload needed; stream picks up new event
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create class'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCC0000),
                    overlayColor: Colors.transparent,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TableCalendar(
              key: ValueKey(_events.length),
              firstDay:
              DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focused,
              calendarFormat: _fmt,
              selectedDayPredicate: (day) =>
                  isSameDay(_selected, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (sel, focused) {
                setState(() {
                  _selected = sel;
                  _focused = focused;
                  _dayEvents = _getEventsForDay(sel);
                });
              },
              onFormatChanged: (fmt) =>
                  setState(() => _fmt = fmt),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color:
                  const Color(0xFFCC0000).withOpacity(0.4),
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
          const SizedBox(height: 10),
          const Divider(height: 1),
          Expanded(
            child: _dayEvents.isEmpty
                ? Center(
              child: Text('No classes on this day',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400])),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _dayEvents.length,
              itemBuilder: (context, i) =>
                  _eventCard(_dayEvents[i], isAdmin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(EventModel event, bool isAdmin) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currUser;
    final timeStr =
        '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}';

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
        final enr = snapshot.hasData && snapshot.data != null
            ? EnrollmentModel.fromFirestore(snapshot.data!)
            : null;
        final status = enr?.status;

        Color? badgeColor, badgeBorder, badgeText;
        String? badgeLabel;

        if (status == 'enrolled') {
          badgeLabel = 'Enrolled';
          badgeColor = Colors.green.shade50;
          badgeBorder = Colors.green.shade200;
          badgeText = Colors.green.shade700;
        } else if (status == 'pending') {
          badgeLabel = 'Requested';
          badgeColor = Colors.blue.shade50;
          badgeBorder = Colors.blue.shade200;
          badgeText = Colors.blue.shade700;
        } else if (status == 'waitlisted') {
          badgeLabel = 'Waitlisted';
          badgeColor = Colors.orange.shade50;
          badgeBorder = Colors.orange.shade200;
          badgeText = Colors.orange.shade700;
        }

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
                  builder: (context) =>
                      ClassManagementScreen(event: event),
                ),
              );
              // stream handles any class changes automatically
            }
                : () => _showClassDetail(event, enr),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.getDispName(),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.inst} · ${event.room}',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500]),
                        ),
                        if (event.rankReq.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            event.rankReq.join(', '),
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (isAdmin) ...[
                          const SizedBox(height: 3),
                          Text(
                            '${event.currEnrollment}/${event.maxCap} students',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badgeLabel != null && !isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: badgeBorder!),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeText),
                      ),
                    ),
                  if (isAdmin)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _confirmDelete(event),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 8, right: 4),
                            child: Icon(Icons.delete_outline,
                                size: 18,
                                color: Colors.grey[350]),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: Colors.grey[350]),
                      ],
                    ),
                  if (!isAdmin && badgeLabel == null)
                    Icon(Icons.chevron_right,
                        size: 18, color: Colors.grey[350]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StudentClassSheet extends StatelessWidget {
  final EventModel event;
  final EnrollmentModel? enrollment;
  final VoidCallback onRequest;
  final VoidCallback onCancel;

  const _StudentClassSheet({
    required this.event,
    required this.enrollment,
    required this.onRequest,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}';
    final status = enrollment?.status;
    final full = event.currEnrollment >= event.maxCap;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(event.getDispName(),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${event.inst} · ${event.room}',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 20),
          _detail('Time', timeStr),
          _detail('Capacity',
              '${event.currEnrollment}/${event.maxCap}${full ? ' · Full' : ''}'),
          if (event.rankReq.isNotEmpty)
            _detail('Ranks', event.rankReq.join(', ')),
          if (event.price > 0)
            _detail('Price', '\$${event.price.toStringAsFixed(2)}'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: status == null
                ? FilledButton(
              onPressed: onRequest,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: Text(
                full ? 'Join waitlist' : 'Request to join',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            )
                : status == 'enrolled'
                ? Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius:
                BorderRadius.circular(50),
                border: Border.all(
                    color: Colors.green.shade200),
              ),
              child: Text(
                'Enrolled',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700),
              ),
            )
                : OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10)),
              ),
              child: Text(
                status == 'waitlisted'
                    ? 'Cancel waitlist request'
                    : 'Cancel request',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[500])),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87))),
        ],
      ),
    );
  }
}