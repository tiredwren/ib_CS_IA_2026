import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'add_product_screen.dart';
import 'purchase_history_screen.dart';

class Proshop extends StatefulWidget {
  const Proshop({super.key});

  @override
  State<Proshop> createState() => _ProshopState();
}

class _ProshopState extends State<Proshop> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<ProductModel> _products = [];

  final List<String> _categories = [
    'All',
    'Uniforms',
    'Weapons',
    'Sparring Gear',
    'Gear Bags',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('category',descending: true)
          .get();

      setState(() {
        _products = productsSnapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  List<ProductModel> get _filteredProducts {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    final isAdmin = authService.isAdmin;

    var filtered = _selectedCategory == 'All'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    // filter by rank for students
    if (!isAdmin && user != null) {
      filtered = filtered.where((p) => p.isAvailableForRank(user.rank)).toList();
    }

    return filtered;
  }

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .delete();

      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ProShop'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseHistoryScreen(),
                  ),
                );
              },
              tooltip: 'Purchase history',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
                if (result == true) {
                  _loadProducts();
                }
              },
              tooltip: 'Add product',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // admin banner
          if (isAdmin)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFF0000).withOpacity(0.1),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFFFF0000)),
                  SizedBox(width: 8),
                  Text(
                    'Admin mode - viewing all products',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF0000),
                    ),
                  ),
                ],
              ),
            ),

          // category filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFFFF0000).withOpacity(0.3),
                  ),
                );
              },
            ),
          ),

          // products grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredProducts[index], isAdmin);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isAdmin) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showProductDetails(product, isAdmin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // product image or placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: product.imageUrl != null
                    ? Image.network(
                  product.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
                    : _buildPlaceholderImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFF0000),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (product.rankRequired.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rank required: ${product.rankRequired.join(", ")}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (!product.inStock) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Out of stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(
        Icons.shopping_bag,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  void _showProductDetails(ProductModel product, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _ProductDetailsSheet(
            product: product,
            isAdmin: isAdmin,
            scrollController: scrollController,
            onDelete: () {
              Navigator.pop(context);
              _showDeleteConfirmation(product);
            },
            onPurchase: () {
              Navigator.pop(context);
              _handlePurchase(product);
            },
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(ProductModel product) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user == null) return;

    String? selectedSize;

    // if product has sizes, show size selection dialog
    if (product.sizes.isNotEmpty) {
      selectedSize = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: product.sizes.map((size) {
              return ListTile(
                title: Text(size),
                onTap: () => Navigator.pop(context, size),
              );
            }).toList(),
          ),
        ),
      );

      if (selectedSize == null) return; // user cancelled
    }

    try {
      // **PAYMENT API INTEGRATION POINT**
      // This is where you would integrate your payment processing
      // For example:
      // final paymentResult = await YourPaymentAPI.processPayment(
      //   amount: product.price,
      //   userId: user.uid,
      //   productId: product.id,
      // );
      // 
      // if (!paymentResult.success) {
      //   throw Exception('Payment failed');
      // }

      // create purchase record
      await FirebaseFirestore.instance.collection('purchases').add({
        'userId': user.uid,
        'productId': product.id,
        'productName': product.name,
        'price': product.price,
        'size': selectedSize,
        'purchaseDate': Timestamp.now(),
        'status': 'pending', // would be 'completed' after payment
        'paymentMethod': 'pending', // would store actual payment method
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing purchase: $e')),
        );
      }
    }
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final ProductModel product;
  final bool isAdmin;
  final ScrollController scrollController;
  final VoidCallback onDelete;
  final VoidCallback onPurchase;

  const _ProductDetailsSheet({
    required this.product,
    required this.isAdmin,
    required this.scrollController,
    required this.onDelete,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // product image
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null
                ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                );
              },
            )
                : const Center(
              child: Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),

          // product name
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // price
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              color: Color(0xFFFF0000),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // category
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                product.category,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),

          // rank requirement
          if (product.rankRequired != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.military_tech, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Rank required: ${product.rankRequired}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],

          // sizes
          if (product.sizes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Sizes: ${product.sizes.join(", ")}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],

          // stock status
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                product.inStock ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: product.inStock ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                product.inStock ? 'In stock' : 'Out of stock',
                style: TextStyle(
                  color: product.inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // action buttons
          if (isAdmin) ...[
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: product.inStock ? onPurchase : null,
                child: Text(product.inStock ? 'Purchase' : 'Out of stock'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}