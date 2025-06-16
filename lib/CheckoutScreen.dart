import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:furnix/MyHomePage.dart';
import 'ProductModel.dart';

class CheckoutScreen extends StatelessWidget {
  final String uid;
  final Map<String, String> address;
  final double totalAmount;
  final List<ProductModel> cartProducts;

  const CheckoutScreen({
    Key? key,
    required this.uid,
    required this.address,
    required this.totalAmount,
    required this.cartProducts,
  }) : super(key: key);

  // Function to place the order and remove cart products
  Future<void> _placeOrder(BuildContext context) async {
    try {
      // Create an order in Firestore
      CollectionReference orders = FirebaseFirestore.instance.collection('orders');
      DocumentReference orderRef = await orders.add({
        'uid': uid,
        'address': address,
        'totalAmount': totalAmount,
        'products': cartProducts.map((product) => product.toMap()).toList(),
        'orderDate': Timestamp.now(),
        'status': 'pending',
      });

      // Clear the cart
      CollectionReference cartRef = FirebaseFirestore.instance.collection('cart');
      await cartRef.doc(uid).update({
        'products': FieldValue.arrayRemove(
          cartProducts.map((product) => {'productId': product.productId}).toList(),
        ),
      });

      // Only one successful toast
      Fluttertoast.showToast(msg: "Order placed successfully!");

      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(uid: uid),
        ),
      );
    } catch (e) {
      // No error toast, just stay silent
      debugPrint("Error placing order: $e"); // Just log for developer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Order Summary"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product List
              const Text("Product List", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                color: Colors.white60,
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartProducts.length,
                  itemBuilder: (context, index) {
                    ProductModel product = cartProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: product.images.isNotEmpty
                            ? Image.network(
                          product.images[0],
                          width: 80,
                          height: 1000,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.image_not_supported, size: 90),
                        title: Text(product.name),
                        subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Shipping Address
              const Text("Shipping Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${address['fullName']}"),
                    Text("Phone: ${address['phone']}"),
                    Text("Address: ${address['addressLine1']} ${address['addressLine2'] ?? ''}"),
                    Text("City: ${address['city']}"),
                    Text("State: ${address['state']}"),
                    Text("Pin Code: ${address['pinCode']}"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text("Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.payment, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text("Cash on Delivery (COD)"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Summary
              const Text("Order Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cartProducts.map((product) {
                    return Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(product.name),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Total Amount
              Text("Total: ₹${totalAmount.toStringAsFixed(2)}"),
              const SizedBox(height: 16),

              // Place Order Button
              ElevatedButton(
                onPressed: () => _placeOrder(context),
                child: const Text("Place Order", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
