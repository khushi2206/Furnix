import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'ProductModel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'AddressScreen.dart'; // Ensure this import is correct

class DirectSalesDetailsPage extends StatefulWidget {
  final ProductModel product;

  DirectSalesDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _DirectSalesDetailsPageState createState() => _DirectSalesDetailsPageState();
}

class _DirectSalesDetailsPageState extends State<DirectSalesDetailsPage> {

  final String userId = "sampleUserId"; // Replace with actual user ID from auth

  @override
  void initState() {
    super.initState();

  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.name ?? "Product Details",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),

      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.images != null && widget.product.images!.isNotEmpty)
              _buildImageView(widget.product.images!),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name ?? "Item Name",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(widget.product.description ?? "No description available",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 20),
                  _buildPriceInfo(),
                  SizedBox(height: 20),
                  _buildBuyNowButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageView(List<String> images) {
    return Container(
      height: 300,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.image, size: 50, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildPriceInfo() {
    return Text("Price: ₹${widget.product.price}",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent));
  }

  Widget _buildBuyNowButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Navigate to AddressScreen with the product details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddressScreen(
                uid: userId,
                totalAmount: widget.product.price, // Pass the total amount
                cartProducts: [widget.product], // Pass the product in the cart
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text("Buy Now", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
