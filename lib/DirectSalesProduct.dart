import 'package:flutter/material.dart';
import 'package:furnix/CartScreen.dart';
import 'package:furnix/DirectSalesDetailsPage.dart';
import 'package:furnix/ProductModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:furnix/WishlistScreen.dart';

class DirectSalesProduct extends StatefulWidget {
  final String uid;
  const DirectSalesProduct({Key? key, required this.uid}) : super(key: key);

  @override
  State<DirectSalesProduct> createState() => _DirectSalesProductState();
}

class _DirectSalesProductState extends State<DirectSalesProduct> {
  bool isLoading = true;
  bool isNoData = false;
  List<ProductModel> directSaleProducts = [];

  @override
  void initState() {
    super.initState();
    fetchDirectSaleProducts();
  }

  Future<void> fetchDirectSaleProducts() async {
    try {
      setState(() => isLoading = true);
      QuerySnapshot productData = await FirebaseFirestore.instance
          .collection('direct_sale_products')
          .where('saleType', isEqualTo: 'direct')
          .get();

      setState(() {
        directSaleProducts = productData.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
        isNoData = directSaleProducts.isEmpty;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isNoData = true;
      });
      Fluttertoast.showToast(msg: "Error fetching products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Top Deals", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : isNoData
                  ? Center(child: Text("No products available"))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: directSaleProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: directSaleProducts[index], uid: widget.uid);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final String uid;
  const ProductCard({Key? key, required this.product, required this.uid}) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isWishlistAdded = false;
  bool isCartAdded = false;

  @override
  void initState() {
    super.initState();
    checkProductInWishlist();
    checkProductInCart();
  }

  Future<void> checkProductInWishlist() async {
    try {
      var wishlistDoc = await FirebaseFirestore.instance
          .collection('wishlist')
          .doc(widget.uid)
          .get();

      if (wishlistDoc.exists) {
        List<dynamic> wishlistProducts = wishlistDoc.data()?['products'] ?? [];
        isWishlistAdded = wishlistProducts.any((p) => p['productId'] == widget.product.productId);
        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error checking wishlist: $e");
    }
  }

  Future<void> checkProductInCart() async {
    try {
      var cartDoc = await FirebaseFirestore.instance
          .collection('cart')
          .doc(widget.uid)
          .get();

      if (cartDoc.exists) {
        List<dynamic> cartProducts = cartDoc.data()?['products'] ?? [];
        isCartAdded = cartProducts.any((p) => p['productId'] == widget.product.productId);
        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error checking cart: $e");
    }
  }

  void toggleWishlist() async {
    try {
      var wishlistDoc = await FirebaseFirestore.instance
          .collection('wishlist')
          .doc(widget.uid)
          .get();

      if (wishlistDoc.exists) {
        List<dynamic> wishlistProducts = wishlistDoc.data()?['products'] ?? [];

        var productIndex = wishlistProducts.indexWhere((p) => p['productId'] == widget.product.productId);

        if (productIndex < 0) {
          wishlistProducts.add({
            'productId': widget.product.productId,
          });
          await wishlistDoc.reference.update({'products': wishlistProducts});
          setState(() => isWishlistAdded = true);
          Fluttertoast.showToast(msg: "Added to Wishlist");
        } else {
          Fluttertoast.showToast(msg: "Product already in Wishlist");
        }
      } else {
        await FirebaseFirestore.instance.collection('wishlist').doc(widget.uid).set({
          'products': [
            {'productId': widget.product.productId}
          ],
          'userId': widget.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => isWishlistAdded = true);
        Fluttertoast.showToast(msg: "Added to Wishlist");
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WishlistScreen(uid: widget.uid)),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Error toggling wishlist: $e");
    }
  }

  void toggleCart() async {
    try {
      var cartDoc = await FirebaseFirestore.instance
          .collection('cart')
          .doc(widget.uid)
          .get();

      if (cartDoc.exists) {
        List<dynamic> cartProducts = cartDoc.data()?['products'] ?? [];

        var productIndex = cartProducts.indexWhere((product) => product['productId'] == widget.product.productId);

        if (productIndex < 0) {
          // Product is not in the cart, add it
          cartProducts.add({
            'productId': widget.product.productId,
          });

          await cartDoc.reference.update({'products': cartProducts});
          setState(() => isCartAdded = true);
          Fluttertoast.showToast(msg: "Product added to Cart");
        } else {
          Fluttertoast.showToast(msg: "Product already in Cart");
        }
      } else {
        // Cart doesn't exist, create a new one
        await FirebaseFirestore.instance.collection('cart').doc(widget.uid).set({
          'products': [
            {'productId': widget.product.productId}
          ],
          'userId': widget.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => isCartAdded = true);
        Fluttertoast.showToast(msg: "Product added to Cart");
      }

      // Navigate to CartScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartScreen(uid: widget.uid)),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Error toggling cart: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DirectSalesDetailsPage(product: widget.product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: widget.product.images.isNotEmpty
                      ? widget.product.images[0]
                      : 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₹${widget.product.price}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.favorite_rounded, color: Colors.red), // Red for Wishlist
                        onPressed: toggleWishlist,
                      ),
                      SizedBox(width: 50), // Space between icons
                      IconButton(
                        icon: Icon(Icons.shopping_cart, color: Colors.blue), // Blue for Cart
                        onPressed: toggleCart,
                      ),
                    ],
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
