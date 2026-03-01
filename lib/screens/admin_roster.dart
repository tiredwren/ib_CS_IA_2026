import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../requirement_data.dart';

class ClassRoster {
  final EventModel? event;
  final List<UserModel> students;
  ClassRoster({required this.event, required this.students});
}

class AdminRosterView extends StatefulWidget {
  const AdminRosterView({super.key});

  @override
  State<AdminRosterView> createState() => _AdminRosterViewState();
}

class _AdminRosterViewState extends State<AdminRosterView> {
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
      final events = eventsSnap.docs.map((d) => EventModel.fromFirestore(d)).toList();

      final enrollSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('isActive', isEqualTo: true)
          .get();

      final Map<String, List<String>> byEvent = {};
      final enrolledUids = <String>{};
      for (final doc in enrollSnap.docs) {
        final d = doc.data();
        final eid = d['eventId'] as String? ?? '';
        final uid = d['userId'] as String? ?? '';
        if (eid.isEmpty || uid.isEmpty) continue;
        byEvent.putIfAbsent(eid, () => []).add(uid);
        enrolledUids.add(uid);
      }

      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final userMap = {for (final d in usersSnap.docs) d.id: UserModel.fromFirestore(d)};

      final rosters = <ClassRoster>[];
      for (final event in events) {
        final uids = byEvent[event.id];
        if (uids == null || uids.isEmpty) continue;
        final students = uids.map((uid) => userMap[uid]).whereType<UserModel>().toList();
        students.sort((a, b) => rankOrder.indexOf(a.rank).compareTo(rankOrder.indexOf(b.rank)));
        rosters.add(ClassRoster(event: event, students: students));
      }

      rosters.sort((a, b) {
        int minIdx(List<UserModel> ss) =>
            ss.map((s) => rankOrder.indexOf(s.rank)).fold(999, (p, i) => i < p ? i : p);
        return minIdx(a.students).compareTo(minIdx(b.students));
      });

      // students with no active enrollment
      final unenrolled = userMap.values
          .where((u) => !enrolledUids.contains(u.uid) && u.role != 'admin')
          .toList();
      unenrolled.sort((a, b) => rankOrder.indexOf(a.rank).compareTo(rankOrder.indexOf(b.rank)));
      if (unenrolled.isNotEmpty) {
        rosters.add(ClassRoster(event: null, students: unenrolled));
      }

      setState(() {
        _rosters = rosters;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _save(String uid, String rank, String program) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'rank': rank,
      'program': program,
    });
    await _load();
  }

  void _showEdit(UserModel student) {
    var rank = student.rank;
    var program = student.program;

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
              Text('Belt Rank',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.8)),
              const SizedBox(height: 8),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: rank,
                    isExpanded: true,
                    items: rankOrder.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) { if (v != null) setModal(() => rank = v); },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Program',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: program,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                onChanged: (v) => program = v,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _save(student.uid, rank, program);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_rosters.isEmpty) {
      return Center(
        child: Text('No enrolled students.', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      );
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