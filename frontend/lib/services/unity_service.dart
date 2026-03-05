import 'dart:convert';
import 'package:http/http.dart' as http;

class UnityService {
  // Use your PC/Headset IP. If using Android Emulator with local Unity, use 10.0.2.2
  static const String unityUrl = "http://10.0.2.2:8080";

  static Future<void> post(Map<String, dynamic> body) async {
    print(
      "DEBUG: Sending to Unity -> ${jsonEncode(body)}",
    ); // Print what is being sent
    try {
      final res = await http
          .post(
            Uri.parse(unityUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 2));

      print(
        "DEBUG: Unity Response Code -> ${res.statusCode}",
      ); // Check if Unity replied
      print(
        "DEBUG: Unity Response Body -> ${res.body}",
      ); // See the Battery/FPS data
    } catch (e) {
      print("DEBUG: Unity Network ERROR -> $e");
    }
  }
}
