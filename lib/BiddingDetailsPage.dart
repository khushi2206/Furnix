import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ProductModel.dart';

class BiddingDetailsPage extends StatefulWidget {
  final ProductModel product;
  const BiddingDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _BiddingDetailsPageState createState() => _BiddingDetailsPageState();
}

class _BiddingDetailsPageState extends State<BiddingDetailsPage> {
  late ProductModel product;
  bool isBiddingEnded = false;
  bool isBidPlaced = false;
  String? currentUserId;
  String? currentUserName;
  TextEditingController bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    product = widget.product;
    checkBiddingStatus();
    _getCurrentUserData();
  }

  void _getCurrentUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
        currentUserName = user.displayName ?? 'Anonymous';
      });
    }
  }

  void checkBiddingStatus() {
    final currentDate = DateTime.now();
    if (product.biddingEndDate != null && product.biddingEndDate!.isBefore(currentDate)) {
      setState(() {
        isBiddingEnded = true;
      });
      finalizeBidding();
    }
  }

  // Place bid only if the new bid is greater than the current one
  Future<void> placeBid(double bidAmount) async {
    if (currentUserId != null && currentUserName != null) {
      if (product.currentBid == null || bidAmount > product.currentBid!) {
        // Store the bid in Firestore
        await FirebaseFirestore.instance
            .collection('bidding_products')
            .doc(product.productId)
            .collection('bids')
            .add({
          'userId': currentUserId,
          'userName': currentUserName,
          'bidAmount': bidAmount,
        });

        // Update the current bid and the user who placed it
        await FirebaseFirestore.instance
            .collection('bidding_products')
            .doc(product.productId)
            .update({
          'currentBid': bidAmount,
          'currentBidUser': currentUserId, // Update the highest bidder
        });

        setState(() {
          isBidPlaced = true; // Mark that a bid has been placed
        });

        // Clear the bid input
        bidController.clear();
      } else {
        // Display a message if the new bid is not greater than the current bid
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bid must be greater than the current bid!'),
        ));
      }
    }
  }

  // Finalize bidding: Find the user with the highest bid and store it as 'finalUser' and add the product to their cart
  Future<void> finalizeBidding() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bidding_products')
        .doc(product.productId)
        .collection('bids')
        .orderBy('bidAmount', descending: true)
        .limit(1) // Get the highest bid
        .get();

    if (snapshot.docs.isNotEmpty) {
      final highestBid = snapshot.docs.first;
      final highestBidUserId = highestBid['userId'];
      final highestBidUserName = highestBid['userName'];
      final highestBidAmount = highestBid['bidAmount'];

      // Store the user with the highest bid as 'finalUser'
      await FirebaseFirestore.instance
          .collection('bidding_products')
          .doc(product.productId)
          .update({
        'finalUser': {
          'userId': highestBidUserId,
          'userName': highestBidUserName,
          'bidAmount': highestBidAmount,
        },
      });

      // Add the product to the winner's cart
      addToCart(highestBidUserId, product.productId);
    }
  }

  // Add the product to the winner's cart
  Future<void> addToCart(String userId, String productId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        // Add the product to the user's cart if it's not already in the cart
        await FirebaseFirestore.instance.collection('cart').doc(userId).update({
          'products': FieldValue.arrayUnion([{'productId': productId}])
        });
      } else {
        // If the user doesn't have a cart, create a new cart with the product
        await FirebaseFirestore.instance.collection('cart').doc(userId).set({
          'products': [{'productId': productId}]
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Product added to cart!'),
      ));
    } catch (e) {
      print("❌ Error adding product to cart: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add product to cart'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(
                  product.images.isNotEmpty ? product.images[0] : '',
                  height: 250,
                  width: 250,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),
              Text(
                product.description,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                'Current Bid: \$${product.currentBid ?? 0}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                'Bid End Date: ${product.biddingEndDate != null ? product.biddingEndDate!.toLocal() : 'N/A'}',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              if (!isBiddingEnded && !isBidPlaced) ...[
                TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Place your bid',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (value) {
                    final bidAmount = double.tryParse(value) ?? 0;
                    if (bidAmount > 0) {
                      placeBid(bidAmount);
                    }
                  },
                ),
                SizedBox(height: 20),
              ] else if (isBidPlaced) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Your bid of \$${product.currentBid} has been placed!',
                    style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Bidding has ended.',
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              SizedBox(height: 20),
              Text(
                'Bidders:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bidding_products')
                    .doc(product.productId)
                    .collection('bids')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Something went wrong.');
                  }

                  final bids = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      final bid = bids[index].data() as Map<String, dynamic>;
                      final userId = bid['userId'];
                      final userName = bid['userName'];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.0),
                          title: Text('$userName (ID: $userId)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Bid Amount: \$${bid['bidAmount']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
