import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'ProductModel.dart';
import 'BiddingDetailsPage.dart';

class BiddingProduct extends StatefulWidget {
  final String uid;
  const BiddingProduct({Key? key, required this.uid}) : super(key: key);

  @override
  State<BiddingProduct> createState() => _BiddingProductState();
}

class _BiddingProductState extends State<BiddingProduct> {
  bool isLoading = true;
  bool isNoData = false;
  List<ProductModel> biddingProducts = [];

  @override
  void initState() {
    super.initState();
    fetchBiddingProducts();
  }

  Future<void> fetchBiddingProducts() async {
    try {
      setState(() => isLoading = true);
      QuerySnapshot productData = await FirebaseFirestore.instance
          .collection('bidding_products')
          .where('saleType', isEqualTo: 'bidding')
          .get();

      setState(() {
        biddingProducts = productData.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
        isNoData = biddingProducts.isEmpty;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching bidding products: $e");
      setState(() {
        isLoading = false;
        isNoData = true;
      });
    }
  }

  String _formatRemainingTime(DateTime endTime) {
    final duration = endTime.difference(DateTime.now());
    if (duration.isNegative) return "Ended";
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return "${hours}h ${minutes}m left";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bidding", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, // Make the app bar transparent
        elevation: 0, // Remove the shadow/elevation
        iconTheme: IconThemeData(color: Colors.black), // Set icon color if needed (e.g., for back button)
        actions: [],
      ),
      extendBodyBehindAppBar: true, // Allow body content to extend behind the app bar
      backgroundColor: Colors.white, // Set background color to white for the entire body
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isNoData
          ? Center(child: Text("No Bidding Products Found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
          : ListView.builder(
        itemCount: biddingProducts.length,
        itemBuilder: (context, index) {
          ProductModel product = biddingProducts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BiddingDetailsPage(product: product),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              shadowColor: Colors.black.withOpacity(0.1),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: product.images?.isNotEmpty == true ? product.images![0] : '',
                        fit: BoxFit.cover,
                        width: 120, // Set proper size for the image
                        height: 120,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
                    SizedBox(width: 15),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name ?? "Item Name",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Current Bid: ₹${product.currentBid?.toStringAsFixed(2) ?? "-"}',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Min Price: ₹${product.price?.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          // Remaining Time
                          if (product.biddingEndDate != null)
                            Text(
                              _formatRemainingTime(product.biddingEndDate!),
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
