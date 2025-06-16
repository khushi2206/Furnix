import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MyHomePage.dart';

class ItemsUploadScreen extends StatefulWidget {
  final String uid;
  const ItemsUploadScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ItemsUploadScreen> createState() => _ItemsUploadScreenState();
}

class _ItemsUploadScreenState extends State<ItemsUploadScreen> with WidgetsBindingObserver {
  List<Uint8List>? imageFiles = [];
  bool isUploading = false;
  bool isRemovingBg = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemDescriptionController = TextEditingController();
  final TextEditingController itemPriceController = TextEditingController();
  final TextEditingController itemStockController = TextEditingController();

  String saleType = "direct";  // Default is direct sale
  DateTime biddingEndDate = DateTime.now().add(Duration(days: 30)); // Default end date is 1 month from now
  TimeOfDay biddingEndTime = TimeOfDay(hour: 12, minute: 0); // Default time is 12:00 PM

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    itemNameController.dispose();
    itemDescriptionController.dispose();
    itemPriceController.dispose();
    itemStockController.dispose();
    super.dispose();
  }

  Widget defaultScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Upload New Product", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: Colors.blue, size: 150),
            ElevatedButton(
              onPressed: showDialogBox,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Add New Product", style: TextStyle(color: Colors.white)),
            ),
            if (isRemovingBg) const CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget uploadFormScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Upload New Product", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => setState(() => imageFiles = []),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: isUploading ? null : () {
              // Dismiss the keyboard before starting the upload
              FocusScope.of(context).unfocus();
              uploadItem();
            },
            icon: const Icon(Icons.upload, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isUploading
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.blue, // Set the color to blue
          ),
        )
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Center(
                  child: imageFiles!.isNotEmpty
                      ? GridView.builder(
                    itemCount: imageFiles!.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return Image.memory(imageFiles![index]);
                    },
                  )
                      : const Icon(Icons.image, color: Colors.grey, size: 150),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Sale Type", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<String>(
                    value: 'direct',
                    groupValue: saleType,
                    onChanged: (value) {
                      setState(() {
                        saleType = value!;
                      });
                    },
                  ),
                  const Text("Direct Sale"),
                  Radio<String>(
                    value: 'bidding',
                    groupValue: saleType,
                    onChanged: (value) {
                      setState(() {
                        saleType = value!;
                        biddingEndDate = DateTime.now().add(Duration(days: 30));
                      });
                    },
                  ),
                  const Text("Bidding"),
                ],
              ),
              const SizedBox(height: 20),
              buildTextField(itemNameController, Icons.title, "Product Name"),
              buildTextField(itemDescriptionController, Icons.description, "Product Description"),
              buildTextField(itemPriceController, Icons.price_change, saleType == 'bidding' ? "Minimum Bid Amount" : "Product Price"),
              if (saleType == 'bidding')
                buildDatePicker(context),
            ],
          ),
        ),
      ),
    );
  }

  // Date Picker for Bidding End Date
  Widget buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.date_range),
          const SizedBox(width: 10),
          Text(
            "Bidding End Date: ${biddingEndDate.toLocal()}".split(' ')[0],
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Pick Date
              DateTime? newDate = await showDatePicker(
                context: context,
                initialDate: biddingEndDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (newDate != null && newDate != biddingEndDate) {
                setState(() {
                  biddingEndDate = newDate;
                });
              }

              // Pick Time after selecting the Date
              TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: biddingEndTime,
              );
              if (newTime != null && newTime != biddingEndTime) {
                setState(() {
                  biddingEndTime = newTime;
                  // Combine date and time to get the full bidding end DateTime
                  biddingEndDate = DateTime(
                    biddingEndDate.year,
                    biddingEndDate.month,
                    biddingEndDate.day,
                    biddingEndTime.hour,
                    biddingEndTime.minute,
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void showDialogBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose an option"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () async {
                Navigator.pop(context);
                pickImages(ImageSource.gallery);  // Gallery option
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Camera"),
              onTap: () async {
                Navigator.pop(context);
                pickImages(ImageSource.camera);  // Camera option
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImages(ImageSource source) async {
    // Pick images from the camera or gallery
    final picker = ImagePicker();
    List<Uint8List> imagesBytes = [];

    if (source == ImageSource.camera) {
      // Open camera for multiple images
      bool continueTaking = true;
      while (continueTaking) {
        final pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          imagesBytes.add(bytes);
        }
        // Ask the user if they want to take another picture
        continueTaking = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Do you want to take another picture?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);  // Continue taking pictures
                  },
                  child: const Text('Yes'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);  // Stop taking pictures
                  },
                  child: const Text('No'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // Gallery selection for multiple images
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          imagesBytes.add(bytes);
        }
      }
    }

    // Update the image files list in the state
    setState(() {
      imageFiles = imagesBytes;
    });
  }

  Future<void> uploadItem() async {
    if (!_formKey.currentState!.validate() || imageFiles!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields and select at least one image.')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user is logged in.');

      List<String> imageUrls = [];
      // Upload images to Firebase Storage
      for (var image in imageFiles!) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = storageRef.putData(image);
        final imageUrl = await (await uploadTask).ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Create a document reference
      final docRef = FirebaseFirestore.instance.collection(
          saleType == 'bidding' ? 'bidding_products' : 'direct_sale_products'
      ).doc();

      // Set fields depending on sale type (bidding or direct sale)
      final productData = {
        'id': docRef.id,
        'name': itemNameController.text,
        'description': itemDescriptionController.text,
        'price': int.parse(itemPriceController.text),
        'images': imageUrls,
        'sellerId': user.uid,
        'createdAt': Timestamp.now(),
        'status': 'available',
        'saleType': saleType,
        // Bidding-specific fields (only for "bidding" sale type)
        if (saleType == 'bidding') ...{
          'biddingEndDate': Timestamp.fromDate(biddingEndDate),
          'currentBid': int.parse(itemPriceController.text), // Set the starting bid
          'currentBidUser': 0, // No one has placed a bid yet
          'minUsers': 2, // Minimum number of users required for bidding
          'isActive': true, // The bidding is active initially
          'biddingWinner': null, // No winner initially
        },
      };

      // Save the product data in Firestore
      await docRef.set(productData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(uid: user.uid)),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed.')));
    } finally {
      setState(() => isUploading = false);
    }
  }

  Widget buildTextField(TextEditingController controller, IconData icon, String labelText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: labelText,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$labelText is required";
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return imageFiles!.isEmpty ? defaultScreen() : uploadFormScreen();
  }
}
