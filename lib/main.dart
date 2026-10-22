import 'package:flutter/material.dart';

void main() => runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CartScreen(),
      ),
    );

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

// =======================================================================
// 6) SCREENS -> kung magdugag og laing screen (detail, checkout, login),
//    hima'g bag-ong class diri sa ubos, o i-separate sa lain nga file
//    (e.g. lib/item_detail_screen.dart) unya i-import sa ibabaw.
//    I-register usab ang routes sa MaterialApp(home: ...) kung ganahan.
// =======================================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // =====================================================================
  // 1) STATE VARIABLES -> ibutang dinhi ang mga data ug controllers
  //    (list, TextEditingController, error messages, selected index, etc.)
  // =====================================================================

  // The single source of truth: the whole cart lives here, in the State.
  final List<CartItem> _items = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Validation messages shown under the text fields.
  String? _nameError;
  String? _priceError;

  // =====================================================================
  // 2) LIFECYCLE -> initState() = ibutang dinhi ang una nga buhaton sa
  //    screen (load data, start timer, listen stream). dispose() = cleanup.
  // =====================================================================

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

  // =====================================================================
  // 3) FUNCTIONS / EVENT HANDLERS -> tanang navigation ug business logic
  //    dinhi ibutang, DILI sa build(). Kung naay pagbag-o sa data,
  //    i-balot ang setState(() { ... }) para mag-rebuild ang screen.
  // =====================================================================

  // Every mutation of the list or of an item happens inside setState(),
  // so Flutter rebuilds the screen with the new values.
  void _increase(int index) {
    setState(() {
      if (_items[index].quantity < 99) _items[index].quantity++;
    });
  }

  void _decrease(int index) {
    setState(() {
      if (_items[index].quantity > 1) _items[index].quantity--;
    });
  }

  void _toggle(int index) {
    setState(() {
      _items[index].gotIt = !_items[index].gotIt;
    });
  }

  // Validate the form, then append a new item (still inside setState()).
  void _addItem() {
    final String name = _nameController.text.trim();
    final double? price = double.tryParse(_priceController.text.trim());

    setState(() {
      _nameError = name.isEmpty ? 'Enter an item name' : null;
      _priceError = (price == null || price <= 0)
          ? 'Enter a number greater than 0'
          : null;

      if (_nameError == null && _priceError == null) {
        _items.add(CartItem(name: name, price: price!));
        _nameController.clear();
        _priceController.clear();
      }
    });

    if (_nameError != null || _priceError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors below.')),
      );
    }
  }

  // Delete every item the user has ticked off.
  void _clearChecked() {
    setState(() {
      _items.removeWhere((item) => item.gotIt);
    });
  }

  // =====================================================================
  // 4) NAVIGATION -> ibutang dinhi ang mga function nga mu-adto og laing
  //    screen. Ayaw ebutang ang Navigator.push sa sulod sa build().
  // =====================================================================

  // Example: open a detail screen for one item, then balik gamit ang pop.
  //
  // void _openDetail(int index) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => ItemDetailScreen(item: _items[index])),
  //   );
  // }
  //
  // void _goBack() => Navigator.pop(context);   // balik sa una nga screen
  //
  // Tungod kay ang _items naa sa State, ang result gikan sa next screen
  // mahimo'ng i-apply dinhi sa didto:
  //
  // final updated = await Navigator.push(...);
  // if (updated != null) setState(() => _items[index] = updated);

  @override
  Widget build(BuildContext context) {
    // ===================================================================
    // 5) BUILD -> UI layout lang dinhi. Ang mga buton i-link lang ngadto sa
    //    functions sa ibabaw gamit ang onPressed: _imongFunction.
    // ===================================================================
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Shopping Cart')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // Expanded keeps the ListView height bounded inside the Column.
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  // Stateless child: receives data + callbacks only.
                  return CartItemTile(
                    item: item,
                    onIncrease: () => _increase(index),
                    onDecrease: () => _decrease(index),
                    onToggle: () => _toggle(index),
                  );
                },
              ),
            ),
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
            // Add-item form with inline validation.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Item name',
                        errorText: _nameError,
                      ),
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Price',
                        errorText: _priceError,
                      ),
                      onChanged: (_) => setState(() => _priceError = null),
                    ),
                  ),
                ],
              ),
            ),
            // Add and Clear checked sit side by side, like the expected screen.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addItem,
                      child: const Text('Add'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearChecked,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear checked'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateless child widget: it only renders the data it is given and
/// forwards button presses through callbacks. It never calls setState().
///
/// Navigation: KUNG ang tile mismo mu-click para muadto og detail screen,
/// idugang og usa pa ka callback dinhi (e.g. final VoidCallback onTap;)
/// unya i-pass gikan sa parent:
///   onTap: () => _openDetail(index),
/// Ang Navigator.context naa gihapon sa parent — ang tile mag-report lang.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onToggle,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // Card look matches the rounded tiles in the expected screen.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: item.gotIt,
              // The parent decides what happens; the tile just reports the tap.
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      decoration:
                          item.gotIt ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    'PHP ${item.price.toStringAsFixed(2)} each',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              // Quantity can never drop below 1.
              onPressed: item.quantity > 1 ? onDecrease : null,
            ),
            Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add),
              // Quantity can never rise above 99.
              onPressed: item.quantity < 99 ? onIncrease : null,
            ),
          ],
        ),
      ),
    );
  }
}
