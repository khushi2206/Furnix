import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'ProductModel.dart';
import 'AddressScreen.dart';

class CartScreen extends StatefulWidget {
  final String uid;
  const CartScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = true;
  bool isNoData = false;
  Set<String> cart = {};
  List<ProductModel> cartProducts = [];

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  /// Fetch Cart Data
  Future<void> fetchCart() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(widget.uid)
          .get();

      if (snapshot.exists && snapshot.data() != null && snapshot.get('products') != null) {
        List<dynamic> products = snapshot.get('products');

        Set<String> productIdSet = Set<String>.from(
            products.map((product) => product['productId'] as String)
        );

        setState(() {
          cart = productIdSet;
          isLoading = false;
          isNoData = false;
        });

        // Fetch normal products and bidding products by IDs
        fetchProductsByIds(cart);
      } else {
        setState(() {
          isLoading = false;
          isNoData = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isNoData = true;
      });
    }
  }

  /// Fetch Products by IDs (Normal + Bidding Products)
  Future<void> fetchProductsByIds(Set<String> productIds) async {
    if (productIds.isEmpty) {
      setState(() {
        isLoading = false;
        isNoData = true;
      });
      return;
    }

    try {
      // Fetch normal products from 'direct_sale_products' collection
      QuerySnapshot normalProductsSnapshot = await FirebaseFirestore.instance
          .collection('direct_sale_products')
          .where(FieldPath.documentId, whereIn: productIds.toList())
          .get();

      // Fetch bidding products from 'bidding_products' collection
      QuerySnapshot biddingProductsSnapshot = await FirebaseFirestore.instance
          .collection('bidding_products')
          .where(FieldPath.documentId, whereIn: productIds.toList())
          .get();

      List<ProductModel> products = [];

      // Combine normal and bidding products
      products.addAll(normalProductsSnapshot.docs.map((doc) => ProductModel.fromFirestore(doc)));
      products.addAll(biddingProductsSnapshot.docs.map((doc) => ProductModel.fromFirestore(doc)));

      setState(() {
        cartProducts = products;
        isLoading = false;
        isNoData = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isNoData = true;
      });
    }
  }

  /// Delete Product from Cart
  Future<void> deleteProductFromCart(String productId) async {
    try {
      // Remove the product from the cart in Firestore
      await FirebaseFirestore.instance.collection('cart').doc(widget.uid).update({
        'products': FieldValue.arrayRemove([{'productId': productId}])
      });

      // Remove the product from the cartProducts list locally
      setState(() {
        cartProducts.removeWhere((product) => product.productId == productId);
      });

      // Show confirmation message
      Fluttertoast.showToast(msg: "Product removed from cart");
    } catch (e) {
      print("❌ Error deleting product: $e");
      Fluttertoast.showToast(msg: "Failed to remove product");
    }
  }

  /// Checkout
  void checkout() async {
    if (cart.isEmpty) {
      Fluttertoast.showToast(msg: "Cart is empty");
      return;
    }

    double totalAmount = getTotalAmount();

    // Navigate to address screen after checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressScreen(
          uid: widget.uid,
          totalAmount: totalAmount,
          cartProducts: cartProducts,
        ),
      ),
    );
  }

  /// Calculate Total Amount
  double getTotalAmount() {
    double total = 0.0;
    for (var product in cartProducts) {
      total += product.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isNoData
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
            const Text("Your cart is empty. Start adding products!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProducts.length,
              itemBuilder: (context, index) {
                ProductModel product = cartProducts[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 6,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: product.images.isNotEmpty ? (product.images[0] as String) : '',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("₹${product.price}", style: const TextStyle(fontSize: 16)),
                        Text("Qty: 1", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteProductFromCart(product.productId);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ₹${getTotalAmount().toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: checkout,
                  child: const Text("Checkout", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
