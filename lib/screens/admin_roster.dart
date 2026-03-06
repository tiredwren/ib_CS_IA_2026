import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../requirement_data.dart';
import '../services/email_service.dart';
import '../models/event_model.dart';
import '../models/requirement_models.dart';

class AdminRosterView extends StatefulWidget {
  const AdminRosterView({super.key});

  @override
  State<AdminRosterView> createState() => _RosterState();
}

class _RosterState extends State<AdminRosterView> {
  bool _loading = true;
  List<ClassRoster> _rosters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final eventsSnap = await FirebaseFirestore.instance.collection('events').get();

      List<EventModel> events = [];
      for (final d in eventsSnap.docs) {
        events.add(EventModel.fromFirestore(d));
      }

      final enrollSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('isActive', isEqualTo: true)
          .get();

      final Map<String, List<String>> byEvent = {};
      final enrolledIds = <String>{};
      for (final doc in enrollSnap.docs) {
        final d = doc.data();
        final eid = d['eventId'] as String? ?? '';
        final uid = d['userId'] as String? ?? '';
        if (eid.isEmpty || uid.isEmpty) continue;
        if (!byEvent.containsKey(eid)) byEvent[eid] = [];
        byEvent[eid]!.add(uid);
        enrolledIds.add(uid);
      }

      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final Map<String, UserModel> userMap = {};
      for (final d in usersSnap.docs) {
        userMap[d.id] = UserModel.fromFirestore(d);
      }

      final rosters = <ClassRoster>[];
      for (final event in events) {
        final uids = byEvent[event.id];
        if (uids == null || uids.isEmpty) continue;

        List<UserModel> students = [];
        for (final uid in uids) {
          if (userMap.containsKey(uid)) students.add(userMap[uid]!);
        }

        students.sort((a, b) {
          final aIdx = rankOrder.indexOf(a.rank);
          final bIdx = rankOrder.indexOf(b.rank);
          return aIdx.compareTo(bIdx);
        });

        rosters.add(ClassRoster(event: event, students: students));
      }

      rosters.sort((a, b) {
        int aMin = 999;
        for (final s in a.students) {
          final idx = rankOrder.indexOf(s.rank);
          if (idx < aMin) aMin = idx;
        }
        int bMin = 999;
        for (final s in b.students) {
          final idx = rankOrder.indexOf(s.rank);
          if (idx < bMin) bMin = idx;
        }
        return aMin.compareTo(bMin);
      });

      List<UserModel> unenrolled = [];
      for (final u in userMap.values) {
        if (!enrolledIds.contains(u.uid) && u.role != 'admin') {
          unenrolled.add(u);
        }
      }

      unenrolled.sort((a, b) {
        final aIdx = rankOrder.indexOf(a.rank);
        final bIdx = rankOrder.indexOf(b.rank);
        return aIdx.compareTo(bIdx);
      });

      if (unenrolled.isNotEmpty) {
        rosters.add(ClassRoster(event: null, students: unenrolled));
      }

      setState(() {
        _rosters = rosters;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _save(String uid, String rank, String program, {
    double? monthlyRate,
    DateTime? nextPaymentDate,
    String? paymentMethod,
    String? notes,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'rank': rank,
      'program': program,
      if (monthlyRate != null) 'monthlyRate': monthlyRate,
      if (nextPaymentDate != null) 'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
    });
    await _load();
  }

  Future<void> _markPaymentReceived(UserModel student) async {
    // check last payment date before allowing another to be recorded
    // prevents admin from accidentally logging duplicate payments
    final lastPaySnap = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: student.uid)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (lastPaySnap.docs.isNotEmpty) {
      final lastDate = (lastPaySnap.docs.first.data()['date'] as Timestamp).toDate();
      final daysSince = DateTime.now().difference(lastDate).inDays;
      if (daysSince < 28) {
        // 28 days rather than strict calendar month to account for slight timing variation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Last payment was $daysSince day${daysSince == 1 ? '' : 's'} ago. Next payment not yet due',
              ),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
        return;
      }
    }

    final now = DateTime.now();

    await FirebaseFirestore.instance.collection('payments').add({
      'userId': student.uid,
      'amount': student.monthlyRate ?? 0,
      'description': 'Monthly Tuition',
      'paymentMethod': student.paymentMethod ?? 'unknown',
      'date': Timestamp.fromDate(now),
    });

    final next = student.nextPaymentDate != null
        ? DateTime(student.nextPaymentDate!.year, student.nextPaymentDate!.month + 1, student.nextPaymentDate!.day)
        : DateTime(now.year, now.month + 1, now.day);

    await FirebaseFirestore.instance.collection('users').doc(student.uid).update({
      'nextPaymentDate': Timestamp.fromDate(next),
    });

    await EmailService.paymentConfirmation(
      userId: student.uid,
      amount: student.monthlyRate ?? 0,
      description: 'Monthly Tuition',
    );

    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment recorded for ${student.fullName}')),
      );
    }
  }

  void _showEdit(UserModel student) {
    var rank = student.rank;
    var program = student.program;
    var rateCtrl = TextEditingController(
      text: student.monthlyRate != null ? student.monthlyRate!.toStringAsFixed(2) : '',
    );
    var notesCtrl = TextEditingController(text: student.notes ?? '');
    var payMethod = student.paymentMethod ?? 'Cash';
    var nextDate = student.nextPaymentDate;

    final methods = ['Cash', 'Check', 'Card', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(student.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(student.email, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 24),

                _sectionLabel('Belt Rank'),
                const SizedBox(height: 8),
                _dropdown(
                  value: rank,
                  items: rankOrder,
                  onChanged: (v) { if (v != null) setModal(() => rank = v); },
                ),
                const SizedBox(height: 16),

                _sectionLabel('Program'),
                const SizedBox(height: 8),
                _textField(controller: TextEditingController(text: program), onChanged: (v) => program = v),
                const SizedBox(height: 24),

                Divider(color: Colors.grey[100]),
                const SizedBox(height: 16),
                _sectionLabel('Payment'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly rate', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          const SizedBox(height: 6),
                          _textField(
                            controller: rateCtrl,
                            prefix: '\$',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Payment method', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          const SizedBox(height: 6),
                          _dropdown(
                            value: payMethod,
                            items: methods,
                            onChanged: (v) { if (v != null) setModal(() => payMethod = v); },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text('Next payment date', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: nextDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setModal(() => nextDate = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      nextDate != null
                          ? '${nextDate!.month}/${nextDate!.day}/${nextDate!.year}'
                          : 'Tap to set date',
                      style: TextStyle(
                        fontSize: 14,
                        color: nextDate != null ? Colors.black87 : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Notes', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                _textField(controller: notesCtrl, maxLines: 3),
                const SizedBox(height: 16),

                if (student.monthlyRate != null)
                  _PayBtn(student: student, onTap: () {
                    Navigator.pop(ctx);
                    _markPaymentReceived(student);
                  }),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _save(
                        student.uid, rank, program,
                        monthlyRate: double.tryParse(rateCtrl.text),
                        nextPaymentDate: nextDate,
                        paymentMethod: payMethod,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFCC0000),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.8),
  );

  Widget _dropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) =>
      DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixText: prefix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_rosters.isEmpty) {
      return Center(child: Text('No enrolled students', style: TextStyle(fontSize: 14, color: Colors.grey[400])));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _rosters.length,
      itemBuilder: (context, i) {
        final r = _rosters[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 20, bottom: 8),
              child: Text(
                r.event?.getDisplayName() ?? 'Unenrolled',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: r.students.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final last = idx == r.students.length - 1;
                  return InkWell(
                    onTap: () => _showEdit(s),
                    borderRadius: BorderRadius.vertical(
                      top: idx == 0 ? const Radius.circular(10) : Radius.zero,
                      bottom: last ? const Radius.circular(10) : Radius.zero,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.fullName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    const SizedBox(height: 2),
                                    Text(s.rank, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                                    if (s.program.isNotEmpty)
                                      Text(s.program, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                  ],
                                ),
                              ),
                              if (s.nextPaymentDate != null && s.nextPaymentDate!.difference(DateTime.now()).inDays <= 3)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Text('Due soon', style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w600)),
                                ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey[350]),
                            ],
                          ),
                        ),
                        if (!last)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Divider(height: 1, color: Colors.grey.shade100),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// separate widget to fetch last payment date independently
// without blocking the rest of the edit sheet from rendering
class _PayBtn extends StatefulWidget {
  final UserModel student;
  final VoidCallback onTap;

  const _PayBtn({required this.student, required this.onTap});

  @override
  State<_PayBtn> createState() => _PayBtnState();
}

class _PayBtnState extends State<_PayBtn> {
  bool _checking = true;
  bool _allowed = true;
  int _daysSince = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final snap = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: widget.student.uid)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // no payment history > always allow first payment
      setState(() => _checking = false);
      return;
    }

    final lastDate = (snap.docs.first.data()['date'] as Timestamp).toDate();
    final days = DateTime.now().difference(lastDate).inDays;

    setState(() {
      _daysSince = days;
      _allowed = days >= 28;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const SizedBox(
        height: 44,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            // null disables the button while keeping the outlined style
            onPressed: _allowed ? widget.onTap : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _allowed ? const Color(0xFFCC0000) : Colors.grey.shade300),
              foregroundColor: const Color(0xFFCC0000),
              disabledForegroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Mark payment received - \$${widget.student.monthlyRate!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (!_allowed) ...[
          const SizedBox(height: 6),
          Text(
            'Last payment was $_daysSince days ago. Next due in ${28 - _daysSince} days',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ],
    );
  }
}