// CLIENT REQUESTED filtering based on events available to student specifications

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class OnlineBooking extends StatefulWidget {
  const OnlineBooking({super.key});

  @override
  State<OnlineBooking> createState() => _OnlineBookingState();
}

class _OnlineBookingState extends State<OnlineBooking> {
  String _selectedType = 'All';
  final List<String> _eventTypes = [
    'All',
    'Class',
    'Seminar',
    'Competition',
    'Testing',
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Column(
      children: [
        // filter dropdown
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text(
                'Event Type:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _eventTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // list of events
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedType == 'All'
                ? FirebaseFirestore.instance
                .collection('events')
                .where('startTime', isGreaterThanOrEqualTo: DateTime.now())
                .orderBy('startTime')
                .snapshots()
                : FirebaseFirestore.instance
                .collection('events')
                .where('type', isEqualTo: _selectedType)
                .where('startTime', isGreaterThanOrEqualTo: DateTime.now())
                .orderBy('startTime')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
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
                        'No events available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final events = snapshot.data!.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .where((event) =>
                  event.isUserEligible(user?.rank ?? 'White Belt'))
                  .toList();

              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events available for your rank',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(context, events[index], user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, UserModel? user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // event info
          Padding(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  DateFormat('MMM dd, yyyy').format(event.startTime),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.person,
                  'Instructor: ${event.instructor}',
                ),
                if (event.price > 0) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.attach_money,
                    '\$${event.price.toStringAsFixed(2)}',
                  ),
                ],
                if (event.requiredRanks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.military_tech,
                    'Required: ${event.requiredRanks.join(", ")}',
                  ),
                ],
                if (event.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // button to 'book now'
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFF0000),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .where('userId', isEqualTo: user?.uid)
                  .where('eventId', isEqualTo: event.id)
                  .snapshots(),
              builder: (context, enrollmentSnapshot) {
                final isEnrolled = enrollmentSnapshot.hasData &&
                    enrollmentSnapshot.data!.docs.isNotEmpty;

                if (isEnrolled) {
                  final enrollment = EnrollmentModel.fromFirestore(
                      enrollmentSnapshot.data!.docs.first);
                  return Center(
                    child: Text(
                      enrollment.status == 'waitlisted'
                          ? 'Waitlisted'
                          : 'Enrolled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return TextButton(
                  onPressed: event.isFull
                      ? () => _joinWaitlist(context, event, user!)
                      : () => _bookEvent(context, event, user!),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    event.isFull ? 'Join Waitlist' : 'Book Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _bookEvent(BuildContext context, EventModel event, UserModel user) async {
    // event booked confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Registration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${event.name}'),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(event.startTime)}'),
            Text('Time: ${DateFormat.jm().format(event.startTime)}'),
            if (event.price > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Price: \$${event.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // enroll user
      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': user.uid,
        'eventId': event.id,
        'status': 'enrolled',
        'enrolledAt': Timestamp.now(),
        'isPaid': false,
      });

      // update count of event enrollment
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .update({
        'currentEnrollment': FieldValue.increment(1),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully registered for event!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinWaitlist(BuildContext context, EventModel event, UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': user.uid,
        'eventId': event.id,
        'status': 'waitlisted',
        'enrolledAt': Timestamp.now(),
        'isPaid': false,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to waitlist!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}