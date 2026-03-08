import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/email_service.dart';
import 'add_product_screen.dart';
import 'purchase_history_screen.dart';
import '../models/purchase_model.dart';
import '../models/product_model.dart';

class Proshop extends StatefulWidget {
  const Proshop({super.key});

  @override
  State<Proshop> createState() => _ProshopState();
}

class _ProshopState extends State<Proshop> {
  String _category = 'All';
  bool _loading = true;
  List<ProductModel> _products = [];

  final List<String> _categories = ['All', 'Uniforms', 'Weapons', 'Sparring Gear', 'Gear Bags'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('category', descending: true)
          .get();
      setState(() {
        _products = snap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  // filter by category + rank eligibility for students
  List<ProductModel> get _filtered {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currUser;
    final isAdmin = auth.isAdmin;

    var list = _category == 'All'
        ? _products
        : _products.where((p) => p.category == _category).toList();

    // rank check can't be done in firestore query, done in model
    if (!isAdmin && user != null) {
      list = list.where((p) => p.rankAvail(user.rank)).toList();
    }
    return list;
  }

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
      await _loadProducts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
    }
  }

  void _confirmDelete(ProductModel product) {
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
              Text('Delete "${product.name}"?', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('This product will be permanently removed from the shop.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
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
                      onPressed: () { Navigator.pop(context); _deleteProduct(product); },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCC0000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _showProductDetails(ProductModel product, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, sc) => _ProductSheet(
          product: product,
          isAdmin: isAdmin,
          scrollCtrl: sc,
          onDelete: () { Navigator.pop(context); _confirmDelete(product); },
          onPurchase: () { Navigator.pop(context); _handlePurchase(product); },
        ),
      ),
    );
  }

  Future<void> _handlePurchase(ProductModel product) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currUser;
    if (user == null) return;

    String? selectedSize;

    // show size picker if product has sizes
    if (product.sizes.isNotEmpty) {
      selectedSize = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
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
              const Text('Select a size', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: product.sizes.map((size) => GestureDetector(
                  onTap: () => Navigator.pop(context, size),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(20)),
                    child: Text(size, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      );
      if (selectedSize == null) return;
    }

    try {
      await FirebaseFirestore.instance.collection('purchases').add({
        'userId': user.uid,
        'productId': product.id,
        'productName': product.name,
        'price': product.price,
        'size': selectedSize,
        'purchaseDate': Timestamp.now(),
        'status': 'pending',
        'paymentMethod': 'pending',
      });

      // email is fire-and-forget
      await EmailService.purchaseConfirmation(
        userId: user.uid,
        productName: product.name,
        price: product.price,
        size: selectedSize,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} added to cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing purchase: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text('Pro Shop', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          if (!isAdmin) ...[
            // student -- history only
            IconButton(
              icon: const Icon(Icons.history_outlined, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PurchaseHistoryScreen(userId: auth.currUser!.uid)),
              ),
            ),
          ] else ...[
            // admin -- history + add product
            IconButton(
              icon: const Icon(Icons.history_outlined, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                if (res == true) _loadProducts();
              },
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // horizontal category filter
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFCC0000) : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : Colors.grey[600]),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(child: Text('No products available', style: TextStyle(fontSize: 14, color: Colors.grey[400])))
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, i) => _buildCard(_filtered[i], isAdmin),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ProductModel product, bool isAdmin) {
    return GestureDetector(
      onTap: () => _showProductDetails(product, isAdmin),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  width: double.infinity,
                  child: product.imageUrl != null
                      ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFCC0000))),
                      const Spacer(),
                      if (!product.inStock)
                        Text('Out of stock', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() =>
      Center(child: Icon(Icons.shopping_bag_outlined, size: 36, color: Colors.grey[300]));
}

class _ProductSheet extends StatelessWidget {
  final ProductModel product;
  final bool isAdmin;
  final ScrollController scrollCtrl;
  final VoidCallback onDelete;
  final VoidCallback onPurchase;

  const _ProductSheet({
    required this.product,
    required this.isAdmin,
    required this.scrollCtrl,
    required this.onDelete,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 200,
              color: const Color(0xFFF5F5F5),
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(child: Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey[300])))
                  : Center(child: Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey[300])),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              Text('\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFCC0000))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(product.category, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('·', style: TextStyle(color: Colors.grey[400])),
              ),
              Text(
                product.inStock ? 'In stock' : 'Out of stock',
                style: TextStyle(fontSize: 13, color: product.inStock ? Colors.green[600] : Colors.grey[400]),
              ),
            ],
          ),
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Available sizes', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: product.sizes.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(20)),
                child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ],
          if (product.rankReq.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Required: ${product.rankReq.join(", ")}',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
          if (product.desc.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.grey[100]),
            const SizedBox(height: 16),
            Text(product.desc, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: isAdmin
                ? OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCC0000)),
                foregroundColor: const Color(0xFFCC0000),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete product', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            )
                : FilledButton(
              onPressed: product.inStock ? onPurchase : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000),
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                product.inStock ? 'Purchase' : 'Out of stock',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: product.inStock ? Colors.white : Colors.grey[400]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
