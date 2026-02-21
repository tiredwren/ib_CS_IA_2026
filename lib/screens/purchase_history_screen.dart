import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  bool _isLoading = true;
  Map<String, List<PurchaseModel>> _purchasesByMonth = {};

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);

    try {
      final purchasesSnapshot = await FirebaseFirestore.instance
          .collection('purchases')
          .orderBy('purchaseDate', descending: true)
          .get();

      Map<String, List<PurchaseModel>> grouped = {};

      for (var doc in purchasesSnapshot.docs) {
        final purchase = PurchaseModel.fromFirestore(doc);
        final monthYear = purchase.monthYear;

        if (!grouped.containsKey(monthYear)) {
          grouped[monthYear] = [];
        }
        grouped[monthYear]!.add(purchase);
      }

      setState(() {
        _purchasesByMonth = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading purchases: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase history'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchasesByMonth.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No purchases yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _purchasesByMonth.keys.length,
        itemBuilder: (context, index) {
          final monthYear = _purchasesByMonth.keys.elementAt(index);
          final purchases = _purchasesByMonth[monthYear]!;

          return _buildMonthSection(monthYear, purchases);
        },
      ),
    );
  }

  Widget _buildMonthSection(String monthYear, List<PurchaseModel> purchases) {
    final totalRevenue = purchases.fold<double>(
      0,
          (sum, purchase) => sum + purchase.price,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                _formatMonthYear(monthYear),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '\$${totalRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF0000),
                ),
              ),
            ],
          ),
        ),
        ...purchases.map((purchase) => _buildPurchaseCard(purchase)),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatMonthYear(String monthYear) {
    final parts = monthYear.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);
    final date = DateTime(year, month);
    return DateFormat('MMMM y').format(date);
  }

  Widget _buildPurchaseCard(PurchaseModel purchase) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(purchase.userId).get(),
      builder: (context, snapshot) {
        String userName = 'Loading...';
        if (snapshot.hasData && snapshot.data!.exists) {
          final user = UserModel.fromFirestore(snapshot.data!);
          userName = user.fullName;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFF0000).withOpacity(0.1),
              child: const Icon(Icons.shopping_bag, color: Color(0xFFFF0000)),
            ),
            title: Text(purchase.productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName),
                Text(
                  DateFormat('MMM d, y - h:mm a').format(purchase.purchaseDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (purchase.size != null)
                  Text(
                    'Size: ${purchase.size}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${purchase.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: purchase.status == 'completed'
                        ? Colors.green
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    purchase.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}