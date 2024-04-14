import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(ChocolatesApp());
}

class ChocolatesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chocolates Order App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Montserrat',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: OrderPage(),
    );
  }
}

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final List<String> products = [
    'Munch',
    'DairyMilk',
    'KitKat',
    'FiveStar',
    'Perk'
  ];
  final Map<String, Map<String, int>> productVariants = {
    'DairyMilk': {
      '10g - Regular': 10,
      '35g - Regular': 30,
      '110g - Regular': 80,
      '110g - Silk': 95
    },
    'Munch': {'10g - Regular': 8, '20g - Regular': 15, '50g - Regular': 35},
    'KitKat': {'20g - Regular': 25, '50g - Regular': 50, '60g - Regular': 50},
    'FiveStar': {'25g - Regular': 20, '50g - Regular': 40, '60g - Regular': 35},
    'Perk': {'15g - Regular': 10, '35g - Regular': 30, '45g - Regular': 40},
  };

  Map<String, int> selectedProducts = {};
  int totalPrice = 0;

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Order Summary"),
            ),
            pw.Table.fromTextArray(
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
                color: PdfColors.purple,
              ),
              data: <List<String>>[
                ['Product', 'Variant', 'Quantity'],
                ...selectedProducts.entries.map(
                  (entry) => [
                    entry.key.split(' - ')[0],
                    entry.key.split(' - ')[1],
                    entry.value.toString()
                  ],
                ),
              ],
            ),
            pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 10)),
            pw.Text(
              "Total Price: ₹$totalPrice",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  void updateProductQuantity(String product, String variant, int quantity) {
    setState(() {
      int price = productVariants[product]![variant]!;
      int currentQuantity = selectedProducts['$product - $variant'] ?? 0;
      int priceDifference = price * (quantity - currentQuantity);
      totalPrice += priceDifference;
      if (quantity > 0) {
        selectedProducts['$product - $variant'] = quantity;
      } else {
        selectedProducts.remove('$product - $variant');
      }
    });
  }

  void confirmOrder() {
    if (selectedProducts.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "No Items",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: Text(
              "Please select items to view cart.",
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    } else {
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Order Confirmation",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  "Order Summary:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _generateOrderSummary(),
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "Total price: ₹$totalPrice",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSuccessMessage();
                },
                child: Text(
                  "Confirm Order",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final bytes = await _generatePdf();
                  Printing.sharePdf(bytes: bytes, filename: 'order_summary.pdf');
                },
                child: Text(
                  "Share",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final bytes = await _generatePdf();
                  Printing.layoutPdf(onLayout: (format) async => bytes);
                },
                child: Text(
                  "Print",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Order Placed",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          content: Text(
            "Your order has been placed successfully. Thank you.",
            style: TextStyle(color: Colors.purple),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  selectedProducts.clear();
                  totalPrice = 0;
                });
              },
              child: Text(
                "OK",
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  String _generateOrderSummary() {
    StringBuffer summary = StringBuffer();
    selectedProducts.forEach((product, quantity) {
      summary.write("$product: $quantity\n");
    });
    return summary.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chocolates Order',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Montserrat',
          ),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        child: Column(
          children: [
            Image.asset(
              'assets/choc_bg.jpg', 
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Welcome to Chocolates Order App',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  String product = products[index];
                  return ExpansionTile(
                    title: Text(
                      product,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    children: productVariants[product]?.entries.map((entry) {
                      String variant = entry.key;
                      int price = entry.value!;
                      return ListTile(
                        title: Text(
                          variant,
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                updateProductQuantity(
                                    product,
                                    variant,
                                    (selectedProducts['$product - $variant'] ?? 0) - 1);
                              },
                            ),
                            Text(
                              (selectedProducts['$product - $variant'] ?? 0).toString(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                updateProductQuantity(
                                    product,
                                    variant,
                                    (selectedProducts['$product - $variant'] ?? 0) + 1);
                              },
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Price: ₹$price',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      );
                    }).toList() ??
                        [],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price: ₹$totalPrice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  confirmOrder();
                },
                child: Text(
                  'View Cart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

