import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furnix/MyProductScreen.dart';
import 'package:furnix/ProductModel.dart';
import 'package:furnix/ProductSearchDelegate.dart';
import 'package:furnix/UserOrderScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CartScreen.dart';
import 'WishlistScreen.dart';
import 'DirectSalesProduct.dart';
import 'ItemsUploadScreen.dart';
import 'LoginScreen.dart';
import 'BiddingProduct.dart';

class MyHomePage extends StatefulWidget {
  final String uid;
  const MyHomePage({Key? key, required this.uid}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ProductModel> allData = [];
  int _currentIndex = 0;
  bool isBiddingSelected = false;
  String userName = "Guest";
  String userImageUrl = "";
  String userId = "";

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });

      try {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc.data()?['name'] ?? "Guest";
            userImageUrl = userDoc.data()?['image'] ?? "";
          });
        } else {
          setState(() {
            userName = "Guest";
            userImageUrl = "";
          });
        }
      } catch (e) {
        setState(() {
          userName = "Guest";
          userImageUrl = "";
        });
      }
    } else {
      setState(() {
        userName = "Guest";
        userImageUrl = "";
      });
    }
  }

  void _toggleProductType(bool isBidding) {
    setState(() => isBiddingSelected = isBidding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white54, // Light Blue Background for AppBar
        foregroundColor: Colors.black87,
        elevation: 1,
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: userImageUrl.isNotEmpty
                      ? NetworkImage(userImageUrl)
                      : null,
                  child: userImageUrl.isEmpty
                      ? Icon(Icons.person, color: Colors.black54)
                      : null,
                ),
              ),
            ),
            SizedBox(width: 10),
            Text(
              getGreeting(),
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            Spacer(),
            // "My Product" text and icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyProductScreen(userId: widget.uid),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.inventory, color: Colors.black54),
                  SizedBox(width: 5),

                ],
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),

      drawer: CustomDrawer(uid: widget.uid, userName: userName, userImageUrl: userImageUrl),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(),
                );
              },
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // 🔥 Banner inserted here 🔥
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0x80ADD8E6), // Light Blue background for Banner
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Shop Trendy\nFurniture',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB73E2F), // Darker Red for contrast
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Discover stylish pieces\nfor your home',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Image.asset(
                          'assets/banner.png', // Put your banner image asset path here
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Bidding and Direct Sale Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _toggleProductType(true),
                child: Text('Bidding'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: isBiddingSelected ? Colors.blue : Colors.white60, // Blue for selected
                  side: BorderSide(color: Colors.grey), // Grey border for unselected
                  minimumSize: Size(140, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _toggleProductType(false),
                child: Text('Direct Sale'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: !isBiddingSelected ? Colors.blue : Colors.white60, // Blue for selected
                  side: BorderSide(color: Colors.grey), // Grey border for unselected
                  minimumSize: Size(140, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          Expanded(
            child: isBiddingSelected
                ? BiddingProduct(uid: widget.uid)
                : DirectSalesProduct(uid: widget.uid),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MyHomePage(uid: widget.uid)));
          } else if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => WishlistScreen(uid: widget.uid)));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => CartScreen(uid: widget.uid)));
          } else if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserOrdersScreen(userId: widget.uid)));
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),  // Changed to Orders icon
        ],
      ),
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 20) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }
}

// Drawer remains unchanged
class CustomDrawer extends StatelessWidget {
  final String uid;
  final String userName;
  final String userImageUrl;

  const CustomDrawer({
    Key? key,
    required this.uid,
    required this.userName,
    required this.userImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0x80ADD8E6)), // Light Blue for Drawer Header
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 30,
                  child: userImageUrl.isNotEmpty
                      ? ClipOval(
                    child: Image.network(userImageUrl, fit: BoxFit.cover, width: 60, height: 60),
                  )
                      : Icon(Icons.person, size: 30, color: Colors.black54),
                ),
                SizedBox(height: 10),
                Text(userName, style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text("Cart"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen(uid: uid))),
          ),
          ListTile(
            leading: Icon(Icons.upload),
            title: Text("Upload Item"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemsUploadScreen(uid: uid))),
          ),
          ListTile(
            leading: Icon(Icons.inventory),
            title: Text("My Product"), // Icon changed to inventory
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyProductScreen(userId: uid))),
          ),
          ListTile(
            leading: Icon(Icons.history), // Icon for orders
            title: Text("My Orders"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserOrdersScreen(userId: uid))),
          ),
          ListTile(
            leading: Icon(Icons.logout_sharp, color: Colors.blue),
            title: Text("Logout"),
            onTap: () async {
              var dialog = AlertDialog(
                content: const Text("Do You Want To Logout"),
                actions: [
                  TextButton(
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text("Yes"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("No"),
                  ),
                ],
              );
              showDialog(
                context: context,
                builder: (context) => dialog,
              );
            },
          ),
        ],
      ),
    );
  }
}
