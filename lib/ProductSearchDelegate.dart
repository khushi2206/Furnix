import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:furnix/BiddingDetailsPage.dart';
import 'ProductModel.dart';
import 'DirectSalesDetailsPage.dart';

class ProductSearchDelegate extends SearchDelegate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    String searchQuery = query.trim().toLowerCase(); // Trim whitespace and convert to lowercase

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        _firestore
            .collection('direct_sale_products')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
            .get(),
        _firestore
            .collection('preowned_products')
            .where('description', isGreaterThanOrEqualTo: searchQuery) // Search by description
            .where('description', isLessThanOrEqualTo: searchQuery + '\uf8ff') // Match description with query
            .get(),
        _firestore
            .collection('bidding_products')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.hasData) {
          // Combine results from all three collections
          var directSaleProducts = snapshot.data![0].docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
          var preownedProducts = snapshot.data![1].docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
          var biddingProducts = snapshot.data![2].docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

          return ListView(
            children: [
              if (directSaleProducts.isNotEmpty) ...[
                _buildCategoryHeader('Direct Sale Products', Colors.blue),
                ...directSaleProducts.map((product) => ProductCard(product: product)),
              ],
              if (biddingProducts.isNotEmpty) ...[
                _buildCategoryHeader('Bidding Products', Colors.red),
                ...biddingProducts.map((product) => ProductCard(product: product, isBidding: true)),
              ],
              if (preownedProducts.isNotEmpty) ...[
                _buildCategoryHeader('Preowned Products', Colors.green),
                ...preownedProducts.map((product) => ProductCard(product: product)),
              ],
              if (directSaleProducts.isEmpty && biddingProducts.isEmpty && preownedProducts.isEmpty)
                Center(child: Text("No products found")),
            ],
          );
        }

        return Center(child: Text("No products found"));
      },
    );
  }

  Widget _buildCategoryHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    String searchQuery = query.trim().toLowerCase(); // Trim whitespace and convert to lowercase

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        _firestore
            .collection('direct_sale_products')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
            .get(),
        _firestore
            .collection('preowned_products')
            .where('description', isGreaterThanOrEqualTo: searchQuery) // Search by description
            .where('description', isLessThanOrEqualTo: searchQuery + '\uf8ff') // Match description with query
            .get(),
        _firestore
            .collection('bidding_products')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.hasData) {
          var directSaleProducts = snapshot.data![0].docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
          var preownedProducts = snapshot.data![1].docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
          var biddingProducts = snapshot.data![2].docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

          return ListView(
            children: [
              if (directSaleProducts.isNotEmpty) ...[
                _buildCategoryHeader('Direct Sale Products', Colors.blue),
                ...directSaleProducts.map((product) => ProductCard(product: product)),
              ],
              if (biddingProducts.isNotEmpty) ...[
                _buildCategoryHeader('Bidding Products', Colors.red),
                ...biddingProducts.map((product) => ProductCard(product: product, isBidding: true)),
              ],
              if (preownedProducts.isNotEmpty) ...[
                _buildCategoryHeader('Preowned Products', Colors.green),
                ...preownedProducts.map((product) => ProductCard(product: product)),
              ],
              if (directSaleProducts.isEmpty && biddingProducts.isEmpty && preownedProducts.isEmpty)
                Center(child: Text("No products found")),
            ],
          );
        }

        return Center(child: Text("No products found"));
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final bool isBidding;

  ProductCard({Key? key, required this.product, this.isBidding = false}) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isInWishlist = false;
  bool isInCart = false;
  final String userId = "sampleUserId";

  @override
  void initState() {
    super.initState();

  }





  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.isBidding) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BiddingDetailsPage(product: widget.product),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectSalesDetailsPage(product: widget.product),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.images.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.product.images[0],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name ?? "Product Name",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.product.description ?? "No description available",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "₹${widget.product.price}",
                      style: TextStyle(fontSize: 16, color: Colors.redAccent),
                    ),
                    if (widget.isBidding) ...[
                      SizedBox(height: 5),
                      Icon(Icons.gavel, color: Colors.red, size: 20),
                      Text(
                        "Bidding Product",
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
