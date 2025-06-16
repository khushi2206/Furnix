import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img; // Ensure this package is added to your pubspec.yaml
import 'dart:io'; // Import for file operations

class ApiClient {
  Future<Uint8List> removeBgApi(String imagePath) async {
    final url = Uri.parse("https://api.remove.bg/v1.0/removebg");
    final request = http.MultipartRequest("POST", url);

    try {
      // Read the image file and convert it to PNG
      final imageBytes = await _convertImageToPng(await _readFileBytes(imagePath));

      // Add image file to the request
      request.files.add(
        http.MultipartFile.fromBytes(
            "image_file",
            imageBytes,
            filename: "image.png" // Ensure the filename is appropriate for PNG
        ),
      );

      // Add API Key to the headers
      request.headers.addAll({
        "X-API-Key": "KgJdBHy9NSqN47JC9FzpFJuL", // Replace with your actual API key
      });

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return responseBody.bodyBytes;
      } else {
        throw Exception("Error occurred with response ${response.statusCode}: ${responseBody.body}");
      }
    } catch (e) {
      throw Exception("Exception occurred: $e");
    }
  }

  // Read the image file as bytes
  Future<Uint8List> _readFileBytes(String filePath) async {
    final file = File(filePath); // Create a File object
    return await file.readAsBytes(); // Read bytes from the file
  }

  // Convert image bytes to PNG
  List<int> _convertImageToPng(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception("Failed to decode image. Please check if the image format is supported.");
    }
    final pngBytes = img.encodePng(image);
    if (pngBytes == null || pngBytes.isEmpty) {
      throw Exception("Failed to encode image to PNG.");
    }
    return pngBytes;
  }
}
