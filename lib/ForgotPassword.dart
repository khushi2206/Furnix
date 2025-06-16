import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'function.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  var isPassVisible = true;
  var isConfirmPassVisible = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool showPasswordFields = false;
  bool isEmailReadOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.purple.shade900,
              Colors.pink.shade800,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Forgot Password",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Enter your email to reset your password",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 10,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Form(
                              key: formKey,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: TextFormField(
                                      readOnly: showPasswordFields,
                                      controller: emailController,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Invalid Email";
                                        } else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                          return "Invalid Email format";
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: "Email",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (showPasswordFields)
                                    Column(
                                      children: [
                                        SizedBox(height: 16),
                                        TextFormField(
                                          controller: passwordController,
                                          obscureText: isPassVisible,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return "Invalid Password";
                                            } else if (value.length < 6) {
                                              return "Min. length should be 6.";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelText: "New Password",
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isPassVisible = !isPassVisible;
                                                });
                                              },
                                              child: Icon(
                                                isPassVisible ? Icons.visibility : Icons.visibility_off_outlined,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        TextFormField(
                                          controller: confirmPasswordController,
                                          obscureText: isConfirmPassVisible,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return "Invalid Confirm Password";
                                            } else if (passwordController.text != value) {
                                              return "Password and confirm password should be the same.";
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelText: "Confirm New Password",
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isConfirmPassVisible = !isConfirmPassVisible;
                                                });
                                              },
                                              child: Icon(
                                                isConfirmPassVisible ? Icons.visibility : Icons.visibility_off_outlined,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        showProgress(context);

                                        var userData = await FirebaseFirestore.instance
                                            .collection('users')
                                            .where('email', isEqualTo: emailController.text.toString())
                                            .get();

                                        if (userData.docs.isNotEmpty) {
                                          if (showPasswordFields) {
                                            var user = userData.docs[0];
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.id)
                                                .update({'password': passwordController.text.toString()});

                                            hideProgressDialog(context);
                                            showErrorMsg("Password reset successfully.");
                                            Navigator.pop(context); // Ensure dialog is popped
                                          } else {
                                            hideProgressDialog(context);
                                            setState(() {
                                              showPasswordFields = true;
                                              isEmailReadOnly = true;
                                            });
                                          }
                                        } else {
                                          hideProgressDialog(context);
                                          showErrorMsg("User not found");
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      showPasswordFields ? "Update Password" : "Set New Password",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showProgress(BuildContext context) async {
  if (!ModalRoute.of(context)!.isCurrent) return;

  showDialog(
    useRootNavigator: false,
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    },
  );
}

void hideProgressDialog(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
  }
}
