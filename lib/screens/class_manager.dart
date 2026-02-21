import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class ClassManagementScreen extends StatefulWidget {
  final EventModel event;

  const ClassManagementScreen({super.key, required this.event});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  bool _isLoading = false;
  List<UserModel> _enrolledStudents = [];
  List<UserModel> _waitlistedStudents = [];
  int _currentEnrollment = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .get();

      List<UserModel> enrolled = [];
      List<UserModel> waitlisted = [];

      for (var enrollmentDoc in enrollmentsSnapshot.docs) {
        final enrollment = EnrollmentModel.fromFirestore(enrollmentDoc);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(enrollment.userId)
            .get();
        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);
          if (enrollment.status == 'enrolled') enrolled.add(user);
          else if (enrollment.status == 'waitlisted') waitlisted.add(user);
        }
      }

      setState(() {
        _enrolledStudents = enrolled;
        _waitlistedStudents = waitlisted;
        _currentEnrollment = enrolled.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
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

        if (_waitlistedStudents.isNotEmpty) {
          final nextStudent = _waitlistedStudents.first;
          final waitlistSnapshot = await FirebaseFirestore.instance
              .collection('enrollments')
              .where('userId', isEqualTo: nextStudent.uid)
              .where('eventId', isEqualTo: widget.event.id)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

          if (waitlistSnapshot.docs.isNotEmpty) {
            await waitlistSnapshot.docs.first.reference.update({'status': 'enrolled'});
            await FirebaseFirestore.instance
                .collection('events')
                .doc(widget.event.id)
                .update({'currentEnrollment': FieldValue.increment(1)});
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
        isFull: _currentEnrollment >= widget.event.maxCapacity,
        onAdd: (student) {
          Navigator.pop(context);
          _addStudent(student);
        },
      ),
    );
  }

  Future<void> _addStudent(UserModel student) async {
    try {
      final isFull = _currentEnrollment >= widget.event.maxCapacity;
      final status = isFull ? 'waitlisted' : 'enrolled';

      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': student.uid,
        'eventId': widget.event.id,
        'status': status,
        'enrolledAt': Timestamp.now(),
        'isActive': true,
        'isPaid': false,
      });

      if (!isFull) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({'currentEnrollment': FieldValue.increment(1)});
      }

      await _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.firstName} ${student.lastName} was $status'),
          ),
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
    final spotsLeft = widget.event.maxCapacity - _currentEnrollment;
    final isFull = spotsLeft <= 0;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // class details
            _ClassDetailsCard(
              event: widget.event,
              currentEnrollment: _currentEnrollment,
            ),
            const SizedBox(height: 24),

            // dealing with enrolled students
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
                  '$_currentEnrollment of ${widget.event.maxCapacity}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add student'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFCC0000),
                    overlayColor: Colors.grey[400],
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
              ],
            ),

            if (!isFull) ...[
              const SizedBox(height: 4),
              Text(
                '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} remaining',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Text(
                'Class full',
                style: TextStyle(fontSize: 12, color: Color(0xFFCC0000)),
              ),
            ],

            const SizedBox(height: 12),

            _enrolledStudents.isEmpty
                ? _EmptyState(label: 'No students enrolled yet')
                : Column(
              children: _enrolledStudents
                  .map((s) => _StudentCard(
                student: s,
                status: 'enrolled',
                onRemove: () => _confirmRemove(s, 'enrolled'),
              ))
                  .toList(),
            ),

            // dealing with waitlisted students
            if (_waitlistedStudents.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Waitlist',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_waitlistedStudents.length}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: _waitlistedStudents
                    .map((s) => _StudentCard(
                  student: s,
                  status: 'waitlisted',
                  onRemove: () => _confirmRemove(s, 'waitlisted'),
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

// class card

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _DetailRow(label: 'Time', value: timeStr),
          _DetailRow(label: 'Instructor', value: event.instructor),
          _DetailRow(label: 'Room', value: event.room),
          _DetailRow(label: 'Ranks', value: ranksStr),
          _DetailRow(
            label: 'Capacity',
            value: '$currentEnrollment / ${event.maxCapacity}',
          ),
          if (event.price > 0)
            _DetailRow(
              label: 'Price',
              value: '\$${event.price.toStringAsFixed(2)}',
              isLast: true,
            ),
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
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[100]),
      ],
    );
  }
}

// student card

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final String status;
  final VoidCallback onRemove;

  const _StudentCard({
    required this.student,
    required this.status,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
    '${student.firstName[0]}${student.lastName.isNotEmpty ? student.lastName[0] : ''}'
        .toUpperCase();

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
            // avatar
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCC0000),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // name + rank
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.firstName} ${student.lastName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.rank} · ${student.program}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // waitlist badge
            if (status == 'waitlisted')
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Waitlist',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),

            // remove button
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

// bottom half of "add student"
class _AddStudentSheet extends StatefulWidget {
  final List<UserModel> students;
  final bool isFull;
  final void Function(UserModel) onAdd;

  const _AddStudentSheet({
    required this.students,
    required this.isFull,
    required this.onAdd,
  });

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students
        .where((s) =>
        '${s.firstName} ${s.lastName} ${s.rank}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add student',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // search
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Divider(height: 1, color: Colors.grey[100]),

            // list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Text(
                  'No students found',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              )
                  : ListView.separated(
                controller: scrollController,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 68, color: Colors.grey[100]),
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  final initials =
                  '${s.firstName[0]}${s.lastName.isNotEmpty ? s.lastName[0] : ''}'
                      .toUpperCase();
                  return InkWell(
                    onTap: () => widget.onAdd(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFCC0000),
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
                                  '${s.firstName} ${s.lastName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.rank} · ${s.program}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
      ),
    );
  }
}