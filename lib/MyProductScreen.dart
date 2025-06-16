import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyProductScreen extends StatelessWidget {
  final String userId;

  MyProductScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Product Details"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: fetchProductDetails(), // Fetch the product details from Firestore
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No products found.'));
          } else {
            // Filter products where sellerId matches the userId
            var filteredProducts = snapshot.data!.docs.where((product) {
              return product['sellerId'] == userId; // Compare sellerId with userId
            }).toList();

            if (filteredProducts.isEmpty) {
              return Center(child: Text('No products from this seller.'));
            } else {
              // Display the filtered products in a ListView
              return ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  var product = filteredProducts[index];

                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          // Display product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              product['images'][0],
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 15),
                          // Display product name and price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Price: ₹${product['price']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  product['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
        },
      ),
    );
  }

  // Fetch product details from the 'direct_sale_products' collection in Firestore
  Future<QuerySnapshot> fetchProductDetails() async {
    try {
      return await FirebaseFirestore.instance
          .collection('direct_sale_products') // Correct collection name
          .get();
    } catch (e) {
      print("Error fetching product details: $e");
      throw e;
    }
  }
}
