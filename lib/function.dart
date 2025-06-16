import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;


AppButton({
  required String buttonName,
  Function()? onPressed,
  Color bgColor = Colors.black, // Default color is black
  double radius = 10,
  double? height,
  double? width,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: width ?? 200, // Use provided width or default to 200
      height: height ?? 50, // Use provided height or default to 50
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Text(
          buttonName,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

imageText(String imagePath, double aspectRatio, double height, double Width) {
  return AspectRatio(
    aspectRatio: aspectRatio,
    child: Image.asset(
      imagePath,
      height: height,
      width: Width,
      fit: BoxFit.cover, // Adjust the BoxFit as per your requirement
    ),
  );
}
showErrorMsg(String error){
  Fluttertoast.showToast(
      msg: "${error}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0
  );
}
showProgressDialog(BuildContext context) async{
  final alert =AlertDialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    contentPadding:EdgeInsets.zero,
    insetPadding: EdgeInsets.symmetric(horizontal: 24),
    content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator()
          ],
        )),
  );
  showDialog(
      useRootNavigator: false,
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context){
        return alert;
      }
  );
}
hideProgress (BuildContext context){
  Navigator.pop(context);
}

void imageselectionActionSheet({
  required BuildContext context,
  required Function() camera,
  required Function() gallery,
}) {
  final action = CupertinoActionSheet(
    title: const Text("Select Files"),
    actions: <Widget>[
      CupertinoActionSheetAction(
        child: Text(
          "Camera",
          style: TextStyle(
            color: Colors.cyan,
          ),
        ),
        onPressed: () {
          Navigator.pop(context); // Close the action sheet
          camera(); // Call the camera function
        },
      ),
      CupertinoActionSheetAction(
        child: Text(
          "Image",
          style: TextStyle(
            color: Colors.blue,
          ),
        ),
        onPressed: () {
          Navigator.pop(context); // Close the action sheet
          gallery(); // Call the gallery function
        },
      ),
    ],
    cancelButton: CupertinoActionSheetAction(
      isDefaultAction: true,
      isDestructiveAction: true,
      child: Text(
        "Cancel",
        style: TextStyle(color: Colors.red),
      ),
      onPressed: () {
        Navigator.pop(context); // Close the action sheet
      },
    ),
  );

  showCupertinoModalPopup(
    context: context,
    builder: (context) => action,
  );
}



void showDialogImageSelection({required BuildContext context, required Function() camera, required Function() gallery,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        content: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Colors.blue,
                ),
                title: Text(
                  "camera",
                  style: TextStyle(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  camera!();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.image,
                  color: Colors.blue,
                ),
                title: Text(
                  "images",
                ),
                onTap: () {
                  Navigator.pop(context);
                  gallery!();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}


bool isPlatformIOS(){
  if(Platform.isIOS){
    return true;
  }
  else{
    return false;
  }
}

Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
      headers: {
        'X-Api-Key': 'your-api-key', // Replace with your Remove.bg API key
      },
      body: {
        'image_file_b64': base64Encode(imageBytes),
        'size': 'auto',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Returns the image bytes with the background removed
    } else {
      print('Error: ${response.statusCode} ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error: $e');
    return null;
  }
}


Future<dynamic> getImage(int i) async {
  final ImagePicker picker = new ImagePicker();

  try {
    if (i == 0) {
      return await picker.pickImage(source: ImageSource.camera);
    } else {
      return await picker.pickImage(source: ImageSource.gallery);
    }
  } catch (e) {}
}



