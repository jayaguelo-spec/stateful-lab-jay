import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stateful_lab_jay/main.dart';

void main() {
  Future<void> pumpCart(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
  }

  /// Looks for [label] inside a cart tile only (not inside the text fields).
  Finder tileText(String label) => find.descendant(
        of: find.byType(CartItemTile),
        matching: find.text(label),
      );

  testWidgets('preloads sample items and shows a live total', (tester) async {
    await pumpCart(tester);

    expect(tileText('Rice'), findsOneWidget);
    expect(tileText('Eggs'), findsOneWidget);
    expect(tileText('Milk'), findsOneWidget);
    expect(find.textContaining('Items: 3'), findsOneWidget);
    expect(find.textContaining('Got it: 0'), findsOneWidget);
    // Rice 60x2 + Eggs 8x12 + Milk 95x1 = 311.00
    expect(find.textContaining('Total: PHP 311.00'), findsOneWidget);
  });

  testWidgets('quantity buttons update the total and respect limits',
      (tester) async {
    await pumpCart(tester);

    // IconButton order: Rice-, Rice+, Eggs-, Eggs+, Milk-, Milk+.
    final iconButtons = find.byType(IconButton);
    // Milk is at quantity 1, so its minus button is disabled.
    expect(tester.widget<IconButton>(iconButtons.at(4)).onPressed, isNull);

    // Rice 2 -> 3 raises the total to 371.00.
    await tester.tap(find.byIcon(Icons.add).at(0));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('Total: PHP 371.00'), findsOneWidget);

    // Back down to 2.
    await tester.tap(iconButtons.at(0));
    await tester.pump();
    expect(find.textContaining('Total: PHP 311.00'), findsOneWidget);

    // Plus stops at 99: keep tapping and confirm it never goes past it.
    for (int i = 0; i < 120; i++) {
      await tester.tap(iconButtons.at(1));
      await tester.pump();
    }
    final tile = tester.widget<CartItemTile>(
      find.ancestor(of: find.text('Rice'), matching: find.byType(CartItemTile)),
    );
    expect(tile.item.quantity, 99);
    expect(tester.widget<IconButton>(iconButtons.at(1)).onPressed, isNull);
  });

  testWidgets('checkbox strikes the name out and Clear checked removes it',
      (tester) async {
    await pumpCart(tester);

    await tester.tap(find.byType(Checkbox).at(1)); // tick Eggs
    await tester.pump();
    expect(find.textContaining('Got it: 1'), findsOneWidget);
    expect(
      tester.widget<Text>(tileText('Eggs')).style?.decoration,
      TextDecoration.lineThrough,
    );

    await tester.tap(find.text('Clear checked'));
    await tester.pump();
    expect(tileText('Eggs'), findsNothing);
    expect(find.textContaining('Items: 2'), findsOneWidget);
    // Rice 120 + Milk 95 = 215.00
    expect(find.textContaining('Total: PHP 215.00'), findsOneWidget);
  });

  testWidgets('validates the form and adds an item when the input is valid',
      (tester) async {
    await pumpCart(tester);

    // Empty name and empty price are rejected.
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Enter an item name'), findsOneWidget);
    expect(find.text('Enter a number greater than 0'), findsOneWidget);
    expect(find.textContaining('Items: 3'), findsOneWidget);

    // A non-numeric price is still rejected.
    await tester.enterText(find.byType(TextField).at(0), 'Bread');
    await tester.enterText(find.byType(TextField).at(1), 'abc');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Enter a number greater than 0'), findsOneWidget);
    expect(tileText('Bread'), findsNothing);

    // A valid price adds the item and clears both fields.
    await tester.enterText(find.byType(TextField).at(1), '45.50');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(tileText('Bread'), findsOneWidget);
    expect(find.textContaining('Items: 4'), findsOneWidget);
    expect(find.text('Enter a number greater than 0'), findsNothing);

    final nameField = tester.widget<TextField>(find.byType(TextField).at(0));
    final priceField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(nameField.controller?.text, isEmpty);
    expect(priceField.controller?.text, isEmpty);
  });
}

