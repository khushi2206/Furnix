import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'CheckoutScreen.dart'; // Ensure this import is correct
import 'ProductModel.dart'; // Import the ProductModel

class AddressScreen extends StatefulWidget {
  final String uid;
  final double totalAmount;
  final List<ProductModel> cartProducts;

  const AddressScreen({
    Key? key,
    required this.uid,
    required this.totalAmount,
    required this.cartProducts,
  }) : super(key: key);

  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Delivery Address")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Enter your shipping address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Full Name
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                hintText: "Full Name",
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(50)], // Limit to 50 characters
            ),
            const SizedBox(height: 16),
            // Phone Number
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Phone Number",
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                FilteringTextInputFormatter.digitsOnly // Allow only numbers
              ],
              maxLength: 10, // Limit to 10 characters
            ),
            const SizedBox(height: 16),
            // Address Line 1
            TextField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                hintText: "Address Line 1",
                labelText: "Address Line 1",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(100)], // Limit to 100 characters
            ),
            const SizedBox(height: 16),
            // Address Line 2
            TextField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                hintText: "Address Line 2 (Optional)",
                labelText: "Address Line 2",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(100)], // Limit to 100 characters
            ),
            const SizedBox(height: 16),
            // City
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                hintText: "City",
                labelText: "City",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(50)], // Limit to 50 characters
            ),
            const SizedBox(height: 16),
            // State
            TextField(
              controller: _stateController,
              decoration: const InputDecoration(
                hintText: "State",
                labelText: "State",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(50)], // Limit to 50 characters
            ),
            const SizedBox(height: 16),
            // Pin Code
            TextField(
              controller: _pinCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Pin Code",
                labelText: "Pin Code",
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(6), // Limit to 6 digits
                FilteringTextInputFormatter.digitsOnly // Allow only numbers
              ],
              maxLength: 6, // Limit to 6 characters
            ),
            const SizedBox(height: 32),
            // Proceed to Checkout Button
            ElevatedButton(
              onPressed: () {
                if (_fullNameController.text.isEmpty ||
                    _phoneController.text.isEmpty ||
                    _addressLine1Controller.text.isEmpty ||
                    _cityController.text.isEmpty ||
                    _stateController.text.isEmpty ||
                    _pinCodeController.text.isEmpty) {
                  Fluttertoast.showToast(msg: "Please fill all fields");
                  return;
                }

                // Validate phone number
                if (_phoneController.text.length != 10) {
                  Fluttertoast.showToast(msg: "Phone number must be 10 digits");
                  return;
                }

                // Validate pin code
                if (_pinCodeController.text.length != 6) {
                  Fluttertoast.showToast(msg: "Pin code must be 6 digits");
                  return;
                }

                // Prepare address map
                Map<String, String> address = {
                  'fullName': _fullNameController.text,
                  'phone': _phoneController.text,
                  'addressLine1': _addressLine1Controller.text,
                  'addressLine2': _addressLine2Controller.text,
                  'city': _cityController.text,
                  'state': _stateController.text,
                  'pinCode': _pinCodeController.text,
                };

                // Proceed to checkout
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      uid: widget.uid,
                      address: address,
                      totalAmount: widget.totalAmount,
                      cartProducts: widget.cartProducts,
                    ),
                  ),
                );
              },
              child: const Text("Proceed to Checkout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
