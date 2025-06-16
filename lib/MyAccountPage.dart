import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAccountPage extends StatefulWidget {
  final String uid;

  const MyAccountPage({Key? key, required this.uid}) : super(key: key);

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  late Future<Map<String, dynamic>> userData;

  @override
  void initState() {
    super.initState();
    userData = fetchUserData();
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users').doc(widget.uid).get();
      return userSnapshot.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  Stream<List<Map<String, dynamic>>> fetchUserProducts() {
    return FirebaseFirestore.instance
        .collection('items')
        .where('userId', isEqualTo: widget.uid) // Matching UID
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
        .toList());
  }

  Stream<List<Map<String, dynamic>>> fetchUserOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: widget.uid) // Matching UID
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Account")),
      body: FutureBuilder(
        future: userData, // Only fetch user data once
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Error loading data"));
          }

          Map<String, dynamic> user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300], // Light grey background
                        child: user['image'] != null
                            ? ClipOval(
                          child: Image.network(
                            user['image'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Icon(Icons.person, size: 40, color: Colors.grey[700]), // Default user icon
                      ),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['username'] ?? "Username",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text("Edit Profile"),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: fetchUserProducts(),
                    builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error loading products"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No products uploaded"));
                      }

                      List<Map<String, dynamic>> products = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Products Uploaded by User", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: 1,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  (product['imageUrl'] != null && product['imageUrl'].isNotEmpty)
                                      ? product['imageUrl']
                                      : 'https://via.placeholder.com/150',
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: fetchUserOrders(),
                    builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error loading orders"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No orders placed"));
                      }

                      List<Map<String, dynamic>> orders = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return ListTile(
                                title: Text(order['productName'] ?? "Product Name"),
                                subtitle: Text(order['orderStatus'] ?? "Order Status"),
                                leading: order['productImage'] != null
                                    ? Image.network(order['productImage'])
                                    : Icon(Icons.shopping_cart),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
