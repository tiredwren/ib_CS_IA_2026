import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/enrollment_model.dart';
import '../models/user_model.dart';

class ClassManagementScreen extends StatefulWidget {
  final EventModel event;
  const ClassManagementScreen({super.key, required this.event});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  bool _loading = false;
  List<UserModel> _studEnrolled = [];
  // pending: requested but not yet confirmed by admin
  List<UserModel> _studPending = [];
  // waitlisted: class is full, ordered by waitlistPosition field
  List<_WaitlistEntry> _studWait = [];
  int _currEnrolled = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .get();

      List<UserModel> enrolled = [];
      List<UserModel> pending = [];
      List<_WaitlistEntry> waitlisted = [];

      for (var enrollmentDoc in enrollmentsSnapshot.docs) {
        final enrollment = EnrollmentModel.fromFirestore(enrollmentDoc);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(enrollment.userId)
            .get();
        if (!userDoc.exists) continue;
        final user = UserModel.fromFirestore(userDoc);

        if (enrollment.status == 'enrolled') {
          enrolled.add(user);
        } else if (enrollment.status == 'pending') {
          pending.add(user);
        } else if (enrollment.status == 'waitlisted') {
          // read position to sort and display order correctly
          final pos = enrollmentDoc.data()['waitlistPosition'] as int? ?? 0;
          waitlisted.add(_WaitlistEntry(user: user, position: pos, docId: enrollmentDoc.id));
        }
      }

      // sort waitlist by position so admin sees requests in the order they came in
      waitlisted.sort((a, b) => a.position.compareTo(b.position));

      setState(() {
        _studEnrolled = enrolled;
        _studPending = pending;
        _studWait = waitlisted;
        _currEnrolled = enrolled.length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  // confirm pending request into the class or onto the waitlist if full
  Future<void> _confirmPending(UserModel student) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: student.uid)
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final full = _currEnrolled >= widget.event.maxCapacity;

      if (full) {
        final newPos = _studWait.length;
        await snap.docs.first.reference.update({
          'status': 'waitlisted',
          'waitlistPosition': newPos,
        });
      } else {
        await snap.docs.first.reference.update({'status': 'enrolled'});
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({'currentEnrollment': FieldValue.increment(1)});
      }

      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(full
                ? '${student.firstName} added to waitlist'
                : '${student.firstName} confirmed into class'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // decline/remove pending request
  Future<void> _declinePending(UserModel student) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: student.uid)
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;
      await snap.docs.first.reference.update({'isActive': false});
      await _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.firstName}\'s request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeStudent(UserModel student, String currentStatus) async {
    try {
      final enrollmentSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: student.uid)
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (enrollmentSnapshot.docs.isEmpty) return;
      await enrollmentSnapshot.docs.first.reference.update({
        'isActive': false,
        'removedAt': Timestamp.now(),
      });

      if (currentStatus == 'enrolled') {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({'currentEnrollment': FieldValue.increment(-1)});

        // promote first person on waitlist (pos 0) to enrolled
        // then move everyone else up by decrementing their position
        if (_studWait.isNotEmpty) {
          final first = _studWait.first;
          await FirebaseFirestore.instance
              .collection('enrollments')
              .doc(first.docId)
              .update({'status': 'enrolled', 'waitlistPosition': 0});

          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.event.id)
              .update({'currentEnrollment': FieldValue.increment(1)});

          // move remaining waitlist positions up
          for (int i = 1; i < _studWait.length; i++) {
            await FirebaseFirestore.instance
                .collection('enrollments')
                .doc(_studWait[i].docId)
                .update({'waitlistPosition': _studWait[i].position - 1});
          }
        }
      }

      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.firstName} removed from class')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing student: $e')),
        );
      }
    }
  }

  Future<void> _showAddStudentDialog() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final enrollmentsSnapshot = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('eventId', isEqualTo: widget.event.id)
        .where('isActive', isEqualTo: true)
        .get();

    final enrolledUserIds = enrollmentsSnapshot.docs
        .map((doc) => doc.data()['userId'] as String)
        .toSet();

    final availableStudents = usersSnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) => !enrolledUserIds.contains(user.uid))
        .toList()
      ..sort((a, b) => a.lastName.compareTo(b.lastName));

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students available to add')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStudentSheet(
        students: availableStudents,
        isFull: _currEnrolled >= widget.event.maxCapacity,
        onAdd: (student) {
          Navigator.pop(context);
          _addStudent(student);
        },
      ),
    );
  }

  Future<void> _addStudent(UserModel student) async {
    try {
      final full = _currEnrolled >= widget.event.maxCapacity;
      final status = full ? 'waitlisted' : 'enrolled';
      final newPos = full ? _studWait.length : 0;

      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': student.uid,
        'eventId': widget.event.id,
        'status': status,
        'enrolledAt': Timestamp.now(),
        'isActive': true,
        'isPaid': false,
        'waitlistPosition': newPos,
      });

      if (!full) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({'currentEnrollment': FieldValue.increment(1)});
      }

      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student.firstName} ${student.lastName} was $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding student: $e')),
        );
      }
    }
  }

  void _confirmRemove(UserModel student, String status) {
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
                'Remove ${student.firstName}?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'They\'ll be removed from this class. If there\'s a waitlist, the next student will be enrolled automatically.',
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
                        _removeStudent(student, status);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCC0000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Remove'),
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
    final spotsLeft = widget.event.maxCapacity - _currEnrolled;
    final full = spotsLeft <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.event.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClassDetailsCard(
              event: widget.event,
              currentEnrollment: _currEnrolled,
            ),
            const SizedBox(height: 24),

            // pending requests section
            if (_studPending.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Pending requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_studPending.length}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                full ? 'Class is full, adding student to waitlist' : 'Admin has been notified of student\'s request to enrol!',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 12),
              Column(
                children: _studPending
                    .map((s) => _PendingCard(
                  student: s,
                  onConfirm: () => _confirmPending(s),
                  onDecline: () => _declinePending(s),
                ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // enrolled section
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Enrolled',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_currEnrolled of ${widget.event.maxCapacity}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add student'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCC0000),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),

            if (!full) ...[
              const SizedBox(height: 4),
              Text(
                '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} remaining',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Text('Class full', style: TextStyle(fontSize: 12, color: Color(0xFFCC0000))),
            ],

            const SizedBox(height: 12),

            _studEnrolled.isEmpty
                ? _EmptyState(label: 'No students enrolled yet')
                : Column(
              children: _studEnrolled
                  .map((s) => _StudentCard(
                student: s,
                status: 'enrolled',
                onRemove: () => _confirmRemove(s, 'enrolled'),
              ))
                  .toList(),
            ),

            // waitlist, ordered by position
            if (_studWait.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  const Text(
                    'Waitlist',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_studWait.length}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Listed in order of request',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 12),
              Column(
                children: _studWait
                    .asMap()
                    .entries
                    .map((e) => _StudentCard(
                  student: e.value.user,
                  status: 'waitlisted',
                  position: e.key + 1,
                  onRemove: () => _confirmRemove(e.value.user, 'waitlisted'),
                ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// small data class to carry waitlist position alongside the user
class _WaitlistEntry {
  final UserModel user;
  final int position;
  final String docId;
  _WaitlistEntry({required this.user, required this.position, required this.docId});
}

class _PendingCard extends StatelessWidget {
  final UserModel student;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _PendingCard({
    required this.student,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
    '${student.firstName[0]}${student.lastName.isNotEmpty ? student.lastName[0] : ''}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.firstName} ${student.lastName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.rank} · ${student.program}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // decline
            GestureDetector(
              onTap: onDecline,
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
              ),
            ),
            // confirm
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCC0000).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Color(0xFFCC0000)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassDetailsCard extends StatelessWidget {
  final EventModel event;
  final int currentEnrollment;
  const _ClassDetailsCard({required this.event, required this.currentEnrollment});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${DateFormat.jm().format(event.startTime)} – ${DateFormat.jm().format(event.endTime)}';
    final ranksStr = event.requiredRanks.isEmpty ? 'All ranks' : event.requiredRanks.join(', ');

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _DetailRow(label: 'Time', value: timeStr),
          _DetailRow(label: 'Instructor', value: event.instructor),
          _DetailRow(label: 'Room', value: event.room),
          _DetailRow(label: 'Ranks', value: ranksStr),
          _DetailRow(label: 'Capacity', value: '$currentEnrollment / ${event.maxCapacity}'),
          if (event.price > 0)
            _DetailRow(label: 'Price', value: '\$${event.price.toStringAsFixed(2)}', isLast: true),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ),
              Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87))),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[100]),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final String status;
  final int? position;
  final VoidCallback onRemove;

  const _StudentCard({
    required this.student,
    required this.status,
    required this.onRemove,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
    '${student.firstName[0]}${student.lastName.isNotEmpty ? student.lastName[0] : ''}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // show position number for waitlisted students
            if (position != null)
              SizedBox(
                width: 24,
                child: Text(
                  '$position',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[400]),
                ),
              ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFCC0000).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFCC0000)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.firstName} ${student.lastName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.rank} · ${student.program}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStudentSheet extends StatefulWidget {
  final List<UserModel> students;
  final bool isFull;
  final void Function(UserModel) onAdd;

  const _AddStudentSheet({required this.students, required this.isFull, required this.onAdd});

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students
        .where((s) =>
        '${s.firstName} ${s.lastName} ${s.rank}'.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Add student', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  if (widget.isFull)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        'Will be waitlisted',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name or rank…',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey[100]),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No students found', style: TextStyle(color: Colors.grey[400], fontSize: 14)))
                  : ListView.separated(
                controller: sc,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, indent: 68, color: Colors.grey[100]),
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  final initials =
                  '${s.firstName[0]}${s.lastName.isNotEmpty ? s.lastName[0] : ''}'.toUpperCase();
                  return InkWell(
                    onTap: () => widget.onAdd(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC0000).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFCC0000))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${s.firstName} ${s.lastName}',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text('${s.rank} · ${s.program}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          Icon(Icons.add, size: 18, color: Colors.grey[350]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
    );
  }
}