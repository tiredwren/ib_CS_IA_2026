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
      // get all active enrollments for this event
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .get();

      List<UserModel> enrolled = [];
      List<UserModel> waitlisted = [];

      for (var enrollmentDoc in enrollmentsSnapshot.docs) {
        final enrollment = EnrollmentModel.fromFirestore(enrollmentDoc);

        // get user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(enrollment.userId)
            .get();

        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);

          if (enrollment.status == 'enrolled') {
            enrolled.add(user);
          } else if (enrollment.status == 'waitlisted') {
            waitlisted.add(user);
          }
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
          SnackBar(content: Text('error loading students: $e')),
        );
      }
    }
  }

  Future<void> _removeStudent(UserModel student, String currentStatus) async {
    try {
      // find the enrollment document
      final enrollmentSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: student.uid)
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (enrollmentSnapshot.docs.isEmpty) return;

      final enrollmentDoc = enrollmentSnapshot.docs.first;

      // mark as removed instead of deleting
      await enrollmentDoc.reference.update({
        'isActive': false,
        'removedAt': Timestamp.now(),
      });

      // if removing an enrolled student, check waitlist
      if (currentStatus == 'enrolled') {
        // update event enrollment count
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({
          'currentEnrollment': FieldValue.increment(-1),
        });

        // move first waitlisted student to enrolled
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
            await waitlistSnapshot.docs.first.reference.update({
              'status': 'enrolled',
            });

            // update event enrollment count
            await FirebaseFirestore.instance
                .collection('events')
                .doc(widget.event.id)
                .update({
              'currentEnrollment': FieldValue.increment(1),
            });
          }
        }
      }

      await _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.firstName} ${student.lastName} removed from class'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error removing student: $e')),
        );
      }
    }
  }

  Future<void> _showAddStudentDialog() async {
    // get all students who aren't already in this class
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
        .toList();

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no available students to add')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('add student'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableStudents.length,
            itemBuilder: (context, index) {
              final student = availableStudents[index];
              return ListTile(
                title: Text('${student.firstName} ${student.lastName}'),
                subtitle: Text('${student.rank} - ${student.program}'),
                onTap: () {
                  Navigator.pop(context);
                  _addStudent(student);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(UserModel student) async {
    try {
      // check if class is full
      final isFull = _currentEnrollment >= widget.event.maxCapacity;
      final status = isFull ? 'waitlisted' : 'enrolled';

      // create enrollment
      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': student.uid,
        'eventId': widget.event.id,
        'status': status,
        'enrolledAt': Timestamp.now(),
        'isActive': true,
        'isPaid': false,
      });

      // update enrollment count if not waitlisted
      if (!isFull) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({
          'currentEnrollment': FieldValue.increment(1),
        });
      }

      await _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${student.firstName} ${student.lastName} added as $status',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error adding student: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddStudentDialog,
            tooltip: 'add student',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // class details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'class details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.access_time,
                        '${DateFormat.jm().format(widget.event.startTime)} - ${DateFormat.jm().format(widget.event.endTime)}'),
                    _buildDetailRow(Icons.person, widget.event.instructor),
                    _buildDetailRow(Icons.meeting_room, widget.event.room),
                    _buildDetailRow(Icons.military_tech,
                        widget.event.requiredRanks.isEmpty
                            ? 'all ranks'
                            : widget.event.requiredRanks.join(', ')),
                    _buildDetailRow(Icons.groups,
                        '$_currentEnrollment / ${widget.event.maxCapacity}'),
                    if (widget.event.price > 0)
                      _buildDetailRow(Icons.attach_money,
                          '\$${widget.event.price.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // enrolled students section
            Text(
              'enrolled students ($_currentEnrollment/${widget.event.maxCapacity})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _enrolledStudents.isEmpty
                ? Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'no enrolled students',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _enrolledStudents.length,
              itemBuilder: (context, index) {
                return _buildStudentCard(
                  _enrolledStudents[index],
                  'enrolled',
                );
              },
            ),
            const SizedBox(height: 24),

            // waitlisted students section
            if (_waitlistedStudents.isNotEmpty) ...[
              Text(
                'waitlisted students (${_waitlistedStudents.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _waitlistedStudents.length,
                itemBuilder: (context, index) {
                  return _buildStudentCard(
                    _waitlistedStudents[index],
                    'waitlisted',
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(UserModel student, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF0000),
          child: Text(
            student.firstName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Text('${student.rank} - ${student.program}'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('remove student'),
                content: Text(
                  'are you sure you want to remove ${student.firstName} ${student.lastName}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _removeStudent(student, status);
                    },
                    child: const Text(
                      'remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}