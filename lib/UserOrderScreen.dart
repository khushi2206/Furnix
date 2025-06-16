import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserOrdersScreen extends StatelessWidget {
  final String userId;  // Pass the userId as a parameter to the constructor

  UserOrdersScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        backgroundColor: Colors.white, // Like Amazon's theme
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('orders') // Fetch orders from the orders collection
            .where('uid', isEqualTo: userId) // Filter orders by current user's ID
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;

              // Extract order details
              String orderId = orders[index].id;
              String fullName = orderData['fullName'] ?? 'Unknown';
              String phone = orderData['phone'] ?? 'Unknown';
              double totalAmount = orderData['totalAmount'] ?? 0.0;
              String orderStatus = orderData['status'] ?? 'Pending'; // Fetch the status from Firestore

              // Extract address fields
              Map<String, dynamic> addressMap = orderData['address'] ?? {};
              String addressLine1 = addressMap['addressLine1'] ?? 'Unknown';
              String addressLine2 = addressMap['addressLine2'] ?? 'Unknown';
              String city = addressMap['city'] ?? 'Unknown';
              String pinCode = addressMap['pinCode'] ?? 'Unknown';
              String state = addressMap['state'] ?? 'Unknown';

              // Assuming products is a list of maps, extract product ids correctly
              List<String> productIds = List<String>.from(
                  orderData['products']?.map((product) => product['id'] ?? '') ?? []
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: Text('Order ID: $orderId', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: $fullName', style: TextStyle(fontSize: 16, color: Colors.black87)),
                        Text('Phone: $phone', style: TextStyle(fontSize: 16, color: Colors.black87)),
                        SizedBox(height: 5),
                        Text(
                          'Address: $addressLine1, $addressLine2, $city, $state, $pinCode',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Total Amount: ₹$totalAmount',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        SizedBox(height: 5),
                        _getOrderStatusWidget(orderStatus), // Status fetched from Firestore
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(
                              orderId: orderId,
                              productIds: productIds,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Order status widget based on Firestore value
  Widget _getOrderStatusWidget(String status) {
    switch (status) {
      case 'Pending':
        return Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.white),
            SizedBox(width: 5),
            Text('Pending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        );
      case 'Shipped':
        return Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.blue),
            SizedBox(width: 5),
            Text('Shipped', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        );
      case 'Delivered':
        return Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 5),
            Text('Delivered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        );
      default:
      // Fetch this status from the Firestore collection or use this default if the status is not found
        return Row(
          children: [
            SizedBox(width: 5),
            Text(status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)), // Use the actual status from Firestore
          ],
        );
    }
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final List<String> productIds;

  OrderDetailsScreen({required this.orderId, required this.productIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), backgroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: $orderId', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Products:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (var productId in productIds)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Product ID: $productId', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
