import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiSyncService {
  static const String baseUrl = "http://10.0.2.2:4040/api/devices";

  // Method to send device info to your backend
  static Future<bool> sendDeviceInfo(Map<String, dynamic> deviceInfo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(deviceInfo),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Data successfully sent to backend API");
        return true;
      } else {
        print("Failed to send data to backend. Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error sending data to backend: $e");
      return false;
    }
  }

  static Future<void> queueFailedApiCall(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> failedCalls = prefs.getStringList('failed_api_calls') ?? [];

    failedCalls.add(jsonEncode(data));
    await prefs.setStringList('failed_api_calls', failedCalls);
    print("API call queued for retry later");
  }
  
  static Future<void> retryFailedApiCalls() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> failedCalls = prefs.getStringList('failed_api_calls') ?? [];

    if (failedCalls.isEmpty) return;

    List<String> stillFailedCalls = [];

    for (String call in failedCalls) {
      Map<String, dynamic> data = jsonDecode(call);
      bool success = await sendDeviceInfo(data);

      if (!success) {
        stillFailedCalls.add(call);
      }
    }

    await prefs.setStringList('failed_api_calls', stillFailedCalls);
  }

}