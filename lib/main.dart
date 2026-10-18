import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: CartScreen()));

/// One line in the cart. The fields are mutable so the parent
/// screen can change them inside setState().
class CartItem {
  String name;
  double price;
  int quantity;
  bool gotIt;

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.gotIt = false,
  });
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // The single source of truth: the whole cart lives here, in the State.
  final List<CartItem> _items = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preload sample items when the screen is first created.
    _items.addAll([
      CartItem(name: 'Rice', price: 60.00, quantity: 2),
      CartItem(name: 'Eggs', price: 8.00, quantity: 12),
      CartItem(name: 'Milk', price: 95.00, quantity: 1),
    ]);
  }

  @override
  void dispose() {
    // Always dispose controllers so listeners/timers do not leak.
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Sum of price x quantity for every item; recomputed on every build.
  double get _total =>
      _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  /// How many items are already ticked off.
  int get _gotItCount => _items.where((item) => item.gotIt).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Shopping Cart')),
      body: SafeArea(
        child: Column(
          children: [
            // Summary bar: updates live because build() re-runs in setState().
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Items: ${_items.length}   Got it: $_gotItCount   '
                'Total: PHP ${_total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              // Expanded keeps the ListView height bounded inside the Column.
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      'PHP ${item.price.toStringAsFixed(2)} x ${item.quantity}',
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
