import 'package:flutter/material.dart';
import 'package:furnix/ProductModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistScreen extends StatefulWidget {
  final String uid;

  const WishlistScreen({Key? key, required this.uid}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool isLoading = true;
  bool isNoData = false;
  Set<String> wishlist = {};
  List<ProductModel> wishlistProducts = [];

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('wishlist')
          .doc(widget.uid)
          .get();

      if (snapshot.exists && snapshot.data() != null && snapshot.get('products') != null) {
        List<dynamic> products = snapshot.get('products');
        Set<String> productIdSet = Set<String>.from(
          products.map((product) => product['productId'] as String),
        );

        setState(() {
          wishlist = productIdSet;
          isLoading = false;
          isNoData = false;
        });

        fetchProductsByIds(wishlist);
      } else {
        setState(() {
          isLoading = false;
          isNoData = true;
        });
      }
    } catch (e) {
      print("❌ Error fetching wishlist: $e");
      setState(() {
        isLoading = false;
        isNoData = true;
      });
    }
  }

  Future<void> fetchProductsByIds(Set<String> productIds) async {
    if (productIds.isEmpty) {
      setState(() {
        isLoading = false;
        isNoData = true;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('direct_sale_products')
          .where(FieldPath.documentId, whereIn: productIds.toList())
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<ProductModel> products = snapshot.docs.map((doc) {
          return ProductModel.fromFirestore(doc);
        }).toList();

        setState(() {
          wishlistProducts = products;
          isLoading = false;
          isNoData = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isNoData = true;
        });
      }
    } catch (e) {
      print("❌ Error fetching products: $e");
      setState(() {
        isLoading = false;
        isNoData = true;
      });
    }
  }

  Future<void> deleteProductFromWishlist(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('wishlist')
          .doc(widget.uid)
          .update({
        'products': FieldValue.arrayRemove([{'productId': productId}])
      });

      setState(() {
        wishlistProducts.removeWhere((product) => product.productId == productId);
      });

      Fluttertoast.showToast(msg: "Product removed from wishlist");
    } catch (e) {
      print("❌ Error deleting product: $e");
    }
  }

  // Add product to the cart
  Future<void> addProductToCart(String productId) async {
    try {
      DocumentReference cartDoc = FirebaseFirestore.instance.collection('cart').doc(widget.uid);

      // Check if the product is already in the cart
      DocumentSnapshot cartSnapshot = await cartDoc.get();
      List<dynamic> cartProducts = cartSnapshot.exists && cartSnapshot.get('products') != null
          ? List.from(cartSnapshot.get('products'))
          : [];

      // Add the new product to the cart
      cartProducts.add({'productId': productId});

      await cartDoc.set({
        'products': cartProducts,
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "Product added to cart");

      // Optionally, remove from wishlist after adding to cart
      deleteProductFromWishlist(productId);
    } catch (e) {
      print("❌ Error adding product to cart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : isNoData
                ? Center(child: Text("No products in wishlist"))
                : Expanded(
              child: ListView.builder(
                itemCount: wishlistProducts.length,
                itemBuilder: (context, index) {
                  return WishlistProductCard(
                    product: wishlistProducts[index],
                    uid: widget.uid,
                    onDelete: deleteProductFromWishlist,
                    onAddToCart: addProductToCart,
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

class WishlistProductCard extends StatelessWidget {
  final ProductModel product;
  final String uid;
  final Function(String) onDelete;
  final Function(String) onAddToCart;

  const WishlistProductCard({
    Key? key,
    required this.product,
    required this.uid,
    required this.onDelete,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the product details page (if needed)
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: product.images.isNotEmpty
                    ? product.images[0]
                    : 'https://via.placeholder.com/150',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text('₹${product.price}', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(product.productId),
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart, color: Colors.green),
              onPressed: () => onAddToCart(product.productId),
            ),
          ],
        ),
      ),
    );
  }
}
