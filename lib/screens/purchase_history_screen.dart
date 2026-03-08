import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/purchase_model.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  // if userId is passed, shows only that user's purchases (student view)
  // if null, shows all purchases (admin view)
  final String? userId;
  const PurchaseHistoryScreen({super.key, this.userId});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool _loading = true;
  // grouped by month/year key e.g. "3/2025"
  Map<String, List<PurchaseModel>> _byMonth = {};
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      Query q = FirebaseFirestore.instance.collection('purchases');
      if (widget.userId != null) q = q.where('userId', isEqualTo: widget.userId);
      q = q.orderBy('purchaseDate', descending: true);

      final snap = await q.get();
      final purchases = snap.docs.map((d) => PurchaseModel.fromFirestore(d)).toList();

      // batch-fetch user names only in admin view
      if (widget.userId == null) {
        final uids = purchases.map((p) => p.userId).toSet();
        for (final uid in uids) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) _userNames[uid] = UserModel.fromFirestore(doc).fullName;
        }
      }

      final Map<String, List<PurchaseModel>> grouped = {};
      for (final p in purchases) {
        grouped.putIfAbsent(p.monthYear, () => []).add(p);
      }

      setState(() {
        _byMonth = grouped;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _setStatus(PurchaseModel purchase, String status, {String? paymentMethod}) async {
    await FirebaseFirestore.instance
        .collection('purchases')
        .doc(purchase.id)
        .update({
      'status': status,
      // only write paymentMethod when completing, not for pending/cancelled
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    });
    await _load();
  }

  // payment method only meaningful when completing a purchase
  void _showPaymentMethodPicker(BuildContext ctx, PurchaseModel purchase) {
    const methods = ['Cash', 'Card', 'Check', 'Other'];
    Navigator.pop(ctx);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx2) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            const Text('Payment method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(purchase.prodName, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),
            ...methods.map((method) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx2);
                  _setStatus(purchase, 'completed', paymentMethod: method.toLowerCase());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(method, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(PurchaseModel purchase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            Text(purchase.prodName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            // show student name in admin view
            Text(
              widget.userId == null ? (_userNames[purchase.userId] ?? '') : '',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            _statusOption(ctx, purchase, 'pending', Colors.orange),
            const SizedBox(height: 8),
            _statusOption(ctx, purchase, 'completed', Colors.green),
            const SizedBox(height: 8),
            _statusOption(ctx, purchase, 'cancelled', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(BuildContext ctx, PurchaseModel purchase, String status, Color color) {
    final current = purchase.status == status;
    return GestureDetector(
      onTap: () {
        if (!current) {
          // prompt for payment method before marking complete
          if (status == 'completed') {
            _showPaymentMethodPicker(ctx, purchase);
          } else {
            Navigator.pop(ctx);
            _setStatus(purchase, status);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: current ? color.withOpacity(0.1) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: current ? Border.all(color: color.withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: current ? color : Colors.black87),
            ),
            if (current) ...[const Spacer(), Icon(Icons.check, size: 16, color: color)],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.userId == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: Text(
          isAdmin ? 'Purchase history' : 'My purchases',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _byMonth.isEmpty
          ? Center(child: Text('No purchases yet', style: TextStyle(fontSize: 15, color: Colors.grey[400])))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _byMonth.keys.length,
        itemBuilder: (context, i) {
          final key = _byMonth.keys.elementAt(i);
          return _buildMonth(key, _byMonth[key]!, isAdmin);
        },
      ),
    );
  }

  Widget _buildMonth(String monthYear, List<PurchaseModel> purchases, bool isAdmin) {
    // sum totals per month for header
    final total = purchases.fold(0.0, (sum, p) => sum + p.price);
    final parts = monthYear.split('/');
    final label = DateFormat('MMMM y').format(DateTime(int.parse(parts[1]), int.parse(parts[0])));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFCC0000))),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: purchases.asMap().entries.map((entry) {
              return _buildRow(entry.value, isAdmin, entry.key, entry.key == purchases.length - 1);
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRow(PurchaseModel p, bool isAdmin, int idx, bool last) {
    final statusColor = p.status == 'completed'
        ? Colors.green
        : p.status == 'cancelled'
        ? Colors.grey
        : Colors.orange;

    return InkWell(
      onTap: isAdmin ? () => _showStatusPicker(p) : null,
      borderRadius: BorderRadius.vertical(
        top: idx == 0 ? const Radius.circular(10) : Radius.zero,
        bottom: last ? const Radius.circular(10) : Radius.zero,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.prodName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 2),
                      if (isAdmin && _userNames[p.userId] != null)
                        Text(_userNames[p.userId]!, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      Text(DateFormat('MMM d, y · h:mm a').format(p.date),
                          style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      if (p.size != null)
                        Text('Size: ${p.size}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${p.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(p.status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                    // admin gets a tap affordance indicator
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.unfold_more, size: 14, color: Colors.grey[350]),
                      ),
                  ],
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
      ),
    );
  }
}