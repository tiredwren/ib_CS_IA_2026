import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loadingPayments = true;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    // admins don't have payment info, skip fetch
    if (!auth.isAdmin) _loadPayments();
  }

  Future<void> _loadPayments() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final uid = auth.currUser?.uid;
    if (uid == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _payments = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
        _loadingPayments = false;
      });
    } catch (e) {
      setState(() => _loadingPayments = false);
      debugPrint('payments error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currUser;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text('Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // name + email shown for all users
          Text(user?.fullName ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),

          if (isAdmin) ...[
            // admins just see role, no payment section
            _sectionHeader('Role'),
            const SizedBox(height: 8),
            _infoCard([_infoRow('Role', 'Admin')]),
          ] else ...[
            _sectionHeader('Profile'),
            const SizedBox(height: 8),
            _infoCard([
              _infoRow('Rank', user?.rank ?? '-'),
              _infoRow('Program', user?.program.isNotEmpty == true ? user!.program : '-'),
              _infoRow('Payment method', _fmtMethod(user?.payMeth)),
            ]),
            const SizedBox(height: 28),

            _sectionHeader('Upcoming payment'),
            const SizedBox(height: 8),
            _upcomingCard(user?.nextPay, user?.monthRate),
            const SizedBox(height: 28),

            _sectionHeader('Payment history'),
            const SizedBox(height: 8),
            if (_loadingPayments)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ))
            else if (_payments.isEmpty)
              _emptyState('No payments recorded yet')
            else
              _infoCard(
                _payments.asMap().entries.map((entry) {
                  final p = entry.value;
                  final last = entry.key == _payments.length - 1;
                  final date = (p['date'] as Timestamp?)?.toDate();
                  return _paymentRow(
                    title: p['description'] ?? 'Monthly Tuition',
                    subtitle: [
                      if (date != null) DateFormat('MMM d, y').format(date),
                      if (p['paymentMethod'] != null) _fmtMethod(p['paymentMethod']),
                    ].join(' · '),
                    amount: (p['amount'] as num?)?.toDouble() ?? 0,
                    last: last,
                  );
                }).toList(),
              ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                auth.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Log out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingCard(DateTime? nextDate, double? rate) {
    if (nextDate == null && rate == null) return _emptyState('No payment info set yet');

    final daysUntil = nextDate?.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFCC0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly tuition', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                const SizedBox(height: 4),
                if (nextDate != null)
                  Text(
                    DateFormat('MMMM d, y').format(nextDate),
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                if (daysUntil != null)
                  Text(
                    daysUntil == 0
                        ? 'Due today'
                        : daysUntil < 0
                        ? 'Overdue by ${daysUntil.abs()} days'
                        : 'In $daysUntil days',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
              ],
            ),
          ),
          if (rate != null)
            Text(
              '\$${rate.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _paymentRow({required String title, required String subtitle, required double amount, required bool last}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ],
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
        if (!last)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }

  Widget _sectionHeader(String text) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  Widget _emptyState(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[400]))),
  );

  // capitalize first letter of payment method string
  String _fmtMethod(String? method) {
    if (method == null || method.isEmpty) return '-';
    return method[0].toUpperCase() + method.substring(1);
  }
}